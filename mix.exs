defmodule Crono.MixProject do
  use Mix.Project

  def project do
    [
      app: :crono,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
end
