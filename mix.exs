defmodule JungleSpec.MixProject do
  use Mix.Project

  def project do
    [
      app: :jungle_spec,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      source_url: source_url(),
      name: "JungleSpec",
      description: "OpenAPI Specification made easier."
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test_lib"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => source_url()
      }
    ]
  end

  defp source_url(), do: "https://github.com/Qarma-inspect/jungle-spec"

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:open_api_spex, "~> 3.12"}
    ]
  end
end
