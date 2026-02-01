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

  def application do
    [
      extra_applications: [:logger, :hackney]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.16.0"},
      {:hackney, "~> 1.25.0"},
      {:jason, "~> 1.0"},
      {:elixir_xml_to_map, "~> 3.0"},
      {:exvcr, "~> 0.17.1", only: :test},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false}
    ]
  end
end
