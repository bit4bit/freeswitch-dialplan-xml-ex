defmodule FreeswitchDialplanXmlEx do
  @moduledoc """
  DialplanXML builder DSL
  """

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :extensions, accumulate: true)
      Module.register_attribute(__MODULE__, :conditions, accumulate: true)

      import unquote(__MODULE__)
    end
  end

  defmacro build do
    quote do
      def render(params) do
        @conditions
        |> Enum.map(fn {extension, fun_condition} ->
          case apply(__MODULE__, fun_condition, [params]) do
            :ok ->
              conditions =
                Enum.map(params, fn {field, expression} ->
                  ~s(<condition field="${#{field}}" expression="#{expression}">)
                end)

              ~s(<extension name="#{extension}">#{conditions}</condition></extension>)

            :not_found ->
              ""
          end
        end)
        |> Enum.join("")
      end
    end
  end

  defmacro extension(name, do: block) do
    quote do
      @extensions unquote(name)

      unquote(block)
    end
  end

  defmacro condition(var, contents) do
    # TOMANDO DE: ExUnit.Case
    contents =
      case contents do
        [do: block] ->
          quote do
            unquote(block)
            :ok
          end

        _ ->
          quote do
            try(unquote(contents))
            :ok
          end
      end

    var = Macro.escape(var)
    contents = Macro.escape(contents, unquote: true)

    fun_name = make_ref() |> :erlang.term_to_binary() |> Base.encode16()

    quote bind_quoted: [fun_name: fun_name, var: var, contents: contents] do
      extension = List.last(@extensions)
      name = "#{extension}-condition-#{fun_name}" |> String.to_atom()

      @conditions {extension, name}
      def unquote(name)(unquote(var)), do: unquote(contents)
      def unquote(name)(_), do: :not_found
    end
  end
end
