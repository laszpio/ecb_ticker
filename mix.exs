defmodule Ticker.MixProject do
  use Mix.Project

  def project do
    [
      app: :ticker,
      version: "0.1.0",
      elixir: "~> 1.14",
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
      {:tesla, "~> 1.20.0"},
      {:hackney, "~> 4.4.3"},
      {:elixir_xml_to_map, "~> 3.0"},
      {:exvcr, "~> 0.17.1", only: :test},
      {:meck, "~> 1.2", only: :test},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
