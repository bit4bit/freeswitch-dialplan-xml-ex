defmodule FreeswitchDialplanXmlExTest do
  use ExUnit.Case

  import FreeswitchDialplanXmlEx

  test "root element" do
    xml =
      dialplanXml do
        extension "echo" do
        end
      end

    assert FreeswitchDialplanXmlEx.render(xml) == ~s(<extension name="echo"></extension>)
  end
end
