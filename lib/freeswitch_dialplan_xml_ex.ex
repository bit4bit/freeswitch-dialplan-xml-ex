defmodule FreeswitchDialplanXmlEx do
  @moduledoc """
  DialplanXML builder DSL
  """

  alias __MODULE__, as: SELF

  defmodule Context do
    defstruct xml: []

    def new() do
      %__MODULE__{}
    end

    def tag(ctx, tag, attrs) do
      xml = ctx.xml ++ [{tag, attrs, ""}]
      %{ctx | xml: xml}
    end

    def tag(ctx, tag, attrs, content) do
      xml = ctx.xml ++ [{tag, attrs, to_string(content)}]
      %{ctx | xml: xml}
    end
  end

  def render(ctx) do
    XmlBuilder.generate(ctx.xml)
  end

  defmacro current_context() do
    quote do
      var!(ctx, SELF)
    end
  end

  defmacro dialplanXml(_opts \\ [], do: block) do
    quote do
      current_context() = Context.new()
      unquote(block)
    end
  end

  defmacro extension(name, do: block) do
    quote do
      Context.tag(current_context(), "extension", %{"name" => unquote(name)}, unquote(block))
    end
  end
end
