defmodule FreeswitchDialplanXmlEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :freeswitch_dialplan_xml_ex,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      elixirc_options: [
        warnings_as_errors: true
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev, runtime: false}]
  end

  defp description() do
    "A opinionated dialplan builder for mod_xml_curl"
  end

  defp package() do
    [
      name: "freeswitch_dialplan_xml_ex",
      files: ~w(lib mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{
        "Chiselapp" =>
          "https://chiselapp.com/user/bit4bit/repository/freeswitch-dialplan-xml-ex/index"
      }
    ]
  end
end
