defmodule Ticker.MixProject do
  use Mix.Project

  def project do
    [
      app: :ticker,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
    [
      {:httpotion, "~> 3.1.0"},
      {:jason, "~> 1.0"},
      {:elixir_xml_to_map, "~> 0.1"},
      {:exvcr, "~> 0.10.3", only: :test}
    ]
  end
end
