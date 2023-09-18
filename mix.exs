defmodule Crono.MixProject do
  use Mix.Project

  def project do
    [
      app: :crono,
      description: "Cron expressions in Elixir",
      version: "1.0.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.3"},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.30", only: :dev},
      {:styler, "~> 0.9", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: "crono",
      licenses: ["MIT"],
      maintainers: ["Christoph Schmatzler"],
      links: %{"GitHub" => "https://github.com/cschmatzler/crono"}
    ]
  end

  defp docs do
    [
      main: "Crono",
      extras: ["CHANGELOG.md"]
    ]
  end
end
