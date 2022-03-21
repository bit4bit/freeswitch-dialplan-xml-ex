#######################################################################
# Copyright 2022 Jovany Leandro G.C <bit4bit@riseup.net>              #
#                                                                     #
# Licensed under the Apache License, Version 2.0 (the "License");     #
# you may not use this file except in compliance with the License.    #
# You may obtain a copy of the License at                             #
#                                                                     #
# http://www.apache.org/licenses/LICENSE-2.0                          #
#                                                                     #
# Unless required by applicable law or agreed to in writing, software #
# distributed under the License is distributed on an "AS IS" BASIS,   #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express        #
# or implied. See the License for the specific language governing     #
# permissions and limitations under the License.                      #
#######################################################################

defmodule FreeswitchDialplanXmlEx do
  @moduledoc """
  DialplanXML builder for freeswitch mod_xml_curl.

  # Example

  ~~~
  defmodule MyFanstaticDialplan do
    use FreeswitchDialplanXmlEx, 
        condition_field_mapping: %{"Caller-Destination-Number" => "destination_number"}
    
    # only render extension who conditions asserts
    extension "echo" do
        condition %{"Caller-Destination-Number" => "9196" do
            action "echo"
        end
    end
    
    extension "extension" do
        condition %{"Caller-Destination-Number" => "1" <> rest do
          action "bridge", "user/1\#{rest}"
        end
    end
  end
  ~~~

  then you can render with params from mod_xml_curl and get xml string.

  ~~~
  MyFantasticDialplan.render(params)
  ~~~
  """

  defmacro __using__(opts) do
    quote do
      Module.register_attribute(__MODULE__, :extensions, accumulate: true)
      Module.register_attribute(__MODULE__, :conditions, accumulate: true)

      @field_mapping Keyword.get(unquote(opts), :condition_field_mapping, %{})

      import unquote(__MODULE__)

      defp expression_from_vars_ast({:%{}, _, []}) do
        raise "need something to match"
      end

      defp expression_from_vars_ast(ast) do
        Macro.prewalker(ast)
        |> Enum.map(& &1)
        |> Enum.filter(fn
          {field, {:<>, _, _}} -> true
          {field, value} when is_binary(field) and (is_binary(value) or is_integer(value)) -> true
          _rest -> false
        end)
        |> Enum.map(fn
          {field, {:<>, _, [value | _]}} ->
            {field, "^#{value}.*$"}

          {field, value} ->
            {field, "^#{value}$"}
        end)
        |> Map.new()
      end

      # thanks Chris McCord Metaprogrammil Elixir book
      defp start_buffer(state), do: Agent.start_link(fn -> state end)
      defp put_buffer(buff, content), do: Agent.update(buff, &[content | &1])
      defp stop_buffer(buff), do: Agent.stop(buff)
      defp output_buffer(buff), do: Agent.get(buff, & &1) |> Enum.reverse() |> Enum.join("")

      defp closed_tag(name, attrs) do
        attr_html = for {key, val} <- attrs, into: "", do: ~s( #{key}="#{val}")
        "<#{name}#{attr_html}/>"
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def render(params) do
        @conditions
        |> Enum.map(fn {extension, fun_condition, vars_ast} ->
          case apply(__MODULE__, fun_condition, [params]) do
            contents when is_binary(contents) ->
              expression_of = expression_from_vars_ast(vars_ast)

              conditions =
                Enum.map(params, fn
                  {field, value} ->
                    expression =
                      case expression_of[field] do
                        nil -> "^#{value}$"
                        expression -> expression
                      end

                    # apply aliases
                    field = Map.get(@field_mapping, field, "${#{field}}")
                    ~s(<condition field="#{field}" expression="#{expression}")
                end)
                |> Enum.reverse()
                |> then(fn
                  [last | rest] ->
                    rest
                    |> Enum.map(&(&1 <> "/>"))
                    |> Enum.join("")
                    # append main condition
                    |> Kernel.<>(last <> ">")
                end)

              ~s(<extension name="#{extension}">#{conditions}#{contents}</condition></extension>)

            _ ->
              ""
          end
        end)
        |> Enum.join("")
      end
    end
  end

  # TAG: <extension..
  defmacro extension(name, do: block) do
    quote do
      @extensions unquote(name)

      unquote(block)
    end
  end

  defmacro tag(name, attrs \\ []) do
    quote do
      put_buffer(
        var!(buff, FreeswitchDialplanXmlEx),
        closed_tag(unquote(name), unquote(attrs))
      )
    end
  end

  defmacro action(name, value) do
    quote bind_quoted: [name: name, value: value] do
      tag("action", application: name, data: value)
    end
  end

  # TAG: <condition..
  defmacro condition(var, do: contents) do
    # TOMANDO DE: ExUnit.Case
    # must returns contents of <condition>..</condition>

    var = Macro.escape(var)
    contents = Macro.escape(contents, unquote: true)

    fun_name = make_ref() |> :erlang.term_to_binary() |> Base.encode16()

    quote bind_quoted: [fun_name: fun_name, var: var, contents: contents] do
      extension = List.first(@extensions)
      name = "#{extension}-condition-#{fun_name}" |> String.to_atom()

      @conditions {extension, name, var}
      def unquote(name)(unquote(var)) do
        {:ok, var!(buff, FreeswitchDialplanXmlEx)} = start_buffer([])
        unquote(contents)
        output = output_buffer(var!(buff, FreeswitchDialplanXmlEx))
        :ok = stop_buffer(var!(buff, FreeswitchDialplanXmlEx))
        output
      end

      def unquote(name)(_), do: :not_found
    end
  end
end
