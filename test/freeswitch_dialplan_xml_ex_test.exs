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

defmodule FreeswitchDialplanXmlExTest do
  use ExUnit.Case

  defmodule ExceptionsInDialplan do
    use FreeswitchDialplanXmlEx

    extension "something to match" do
      condition %{} do
      end
    end
  end

  defmodule BasicDialplan do
    use FreeswitchDialplanXmlEx,
      condition_field_mapping: %{"alias" => "destination_number"}

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

    extension "freeswitch action element" do
      condition %{"A" => "1"} do
        action("log", "INFO melo")
      end
    end

    extension "freeswitch action element dynamic value" do
      condition %{"A" => a} do
        action("log", "INFO GOT #{a}")
      end
    end

    extension "alias condition field" do
      condition %{"alias" => "44"} do
      end
    end
  end

  test "freeswitch alias condition field" do
    assert BasicDialplan.render(%{"alias" => "44"}) =~
             ~s(<extension name="alias condition field"><condition field="destination_number" expression="^44$"></condition></extension>)
  end

  test "freeswitch action element with dynamic value" do
    # we expect de expression same as value because we want to be a executable dialplan
    assert BasicDialplan.render(%{"A" => "44"}) =~
             ~s(<extension name="freeswitch action element dynamic value"><condition field="${A}" expression="^44$"><action application="log" data="INFO GOT 44"/></condition></extension>)
  end

  test "freeswitch action element" do
    assert BasicDialplan.render(%{"A" => "1"}) =~
             ~s(<extension name="freeswitch action element"><condition field="${A}" expression="^1$"><action application="log" data="INFO melo"/></condition></extension>)
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

  test "exception on empty match condition" do
    assert_raise(RuntimeError, fn ->
      ExceptionsInDialplan.render(%{"test" => "123"})
    end)
  end
end
