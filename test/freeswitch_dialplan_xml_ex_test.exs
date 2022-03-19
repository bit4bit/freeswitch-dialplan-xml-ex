defmodule FreeswitchDialplanXmlExTest do
  use ExUnit.Case

  defmodule BasicDialplan do
    use FreeswitchDialplanXmlEx

    extension "equal expression" do
      condition %{"test" => "123"} do
      end
    end

    extension "concatenation expression" do
      condition %{"test" => "12" <> _rest} do
      end
    end

    extension "multiple conditions" do
      condition %{"A" => "1", "B" => "2"} do
      end
    end

    build()
  end

  test "multiple conditions" do
    assert BasicDialplan.render(%{"A" => "1", "B" => "2"}) =~
             ~s(<extension name="multiple conditions"><condition field="${A}" expression="^1$"/><condition field="${B}" expression="^2$"></condition></extension>)
  end

  test "dialplan equal expresion" do
    assert BasicDialplan.render(%{"test" => "123"}) =~
             ~s(<extension name="equal expression"><condition field="${test}" expression="^123$"></condition></extension>)
  end

  test "dialplan with concatenation expression" do
    assert BasicDialplan.render(%{"test" => "123"}) =~
             ~s(<extension name="concatenation expression"><condition field="${test}" expression="^12.+$"></condition></extension>)
  end
end
