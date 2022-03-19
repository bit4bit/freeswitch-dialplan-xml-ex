defmodule FreeswitchDialplanXmlExTest do
  use ExUnit.Case

  defmodule BasicDialplan do
    use FreeswitchDialplanXmlEx

    extension "echo" do
      condition %{"test" => "123"} do
      end
    end

    build()
  end

  test "dialplan with empty extension" do
    assert BasicDialplan.render(%{"test" => "123"}) ==
             ~s(<extension name="echo"><condition field="${test}" expression="123"></condition></extension>)
  end
end
