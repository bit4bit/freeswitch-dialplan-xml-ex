defmodule FreeswitchDialplanXmlEx do
  @moduledoc """
  DialplanXML builder DSL
  """

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :extensions, accumulate: true)
      Module.register_attribute(__MODULE__, :conditions, accumulate: true)

      import unquote(__MODULE__)

      defp expression_from_vars_ast(ast) do
        Macro.prewalker(ast)
        |> Enum.map(& &1)
        |> Enum.filter(fn
          {field, {:<>, _, _}} -> true
          {field, value} when is_binary(field) and is_binary(value) -> true
          _rest -> false
        end)
        |> Enum.map(fn
          {field, {:<>, _, [value | _]}} -> {field, "^#{value}.+$"}
          {field, value} -> {field, "^#{value}$"}
        end)
        |> Map.new()
      end
    end
  end

  defmacro build do
    quote do
      def render(params) do
        @conditions
        |> Enum.map(fn {extension, fun_condition, vars_ast} ->
          case apply(__MODULE__, fun_condition, [params]) do
            contents when is_binary(contents) ->
              expression_of = expression_from_vars_ast(vars_ast)

              conditions =
                Enum.map(params, fn
                  {field, _values} ->
                    expression = expression_of[field]

                    ~s(<condition field="${#{field}}" expression="#{expression}")
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

  # TAG: <condition..
  defmacro condition(var, do: block) do
    # TOMANDO DE: ExUnit.Case
    # must returns contents of <condition>..</condition>
    contents =
      quote do
        case unquote(block) do
          nil -> ""
          rest -> rest
        end
      end

    var = Macro.escape(var)
    contents = Macro.escape(contents, unquote: true)

    fun_name = make_ref() |> :erlang.term_to_binary() |> Base.encode16()

    quote bind_quoted: [fun_name: fun_name, var: var, contents: contents] do
      extension = List.first(@extensions)
      name = "#{extension}-condition-#{fun_name}" |> String.to_atom()

      @conditions {extension, name, var}
      def unquote(name)(unquote(var)), do: unquote(contents)
      def unquote(name)(_), do: :not_found
    end
  end
end
