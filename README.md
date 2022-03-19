# FreeswitchDialplanXmlEx

A diaplan builder for **mod_xml_curl**.

~~~elixir
defmodule MyFanstaticDialplan do
    use FreeswitchDialplanXmlEx, 
        alias: %{"Caller-Destination-Number" => "destination_number"}
    
    # only render extension who conditions asserts
    extension "echo" do
        condition %{"Caller-Destination-Number" => "9196" do
            action "echo"
        end
    end
    
    extension "extension" do
        condition %{"Caller-Destination-Number" => "1" <> rest do
          action "bridge", "user/1#{rest}"
        end
    end
end

...

IO.inspect MyFanstaticDialplan.render(params_from_mod_xml_curl_as_map)

<extension name"echo">
 <condition field="${destination_number}" expression="^9196">
   <action application="echo"/>
 </condition>
 <condition field="${variable_destination_number}" expression="^1.+$">
   <action application="bridge" data="user/1..string interpolated.."/>
 </condition>
</extension>
~~~

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `freeswitch_dialplan_xml_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:freeswitch_dialplan_xml_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/freeswitch_dialplan_xml_ex>.

