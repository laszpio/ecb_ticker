defmodule Ticker do
  @moduledoc """
  Provides current and historical (90 days) foreign exchange rates published by the
  [European Central Bank](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html).
  """

  @doc """
  Provides daily exchange rates.
  """
  def daily, do: query(:daily)

  @doc """
  Provides historical 90 days exchange rates.
  """
  def historical, do: query(:historical)

  defp query(scope) do
    case Tesla.get(endpoint_url(scope)) do
      {:ok, response} ->
        case parse_response_body(response.body) do
          {:ok, response} -> process_response_data(response)
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Parses XML response body and returns data container
  """
  def parse_response_body(response) do
    case XmlToMap.naive_map(response) do
      %{"gesmes:Envelope" => data} -> {:ok, data}
      {:error, message} -> {:error, message}
    end
  end

  defp process_response_data(data) do
    data |> get_in(["Cube", "Cube"]) |> extract_rates()
  end

  @doc """
  Extracts rates from data container
  """
  def extract_rates(data) when is_map(data) do
    %{
      base: "EUR",
      date: rates_date(data),
      rates: Enum.map(data |> get_in(["#content", "Cube"]), &currency_rate(&1))
    }
  end

  def extract_rates(data) when is_list(data) do
    data |> Enum.map(&extract_rates(&1))
  end

  defp rates_date(data) do
    {:ok, date} = data |> Map.fetch!("-time") |> Date.from_iso8601()
    date
  end

  defp currency_rate(data) do
    {:ok, currency} = Map.fetch(data, "-currency")
    {:ok, rate} = Map.fetch(data, "-rate")
    {rate, ""} = Float.parse(rate)

    {currency, rate}
  end

  @doc """
  Builds and url to EBC currency API.

  Data feeds:
    - :daily returns url to endpoint with latest published exchange rates
    - :historical returns url to endpoints with exchange rates published within
      last 90 days
  """
  def endpoint_url(feed) do
    base_url = "https://www.ecb.europa.eu/stats/eurofxref"

    case feed do
      :historical -> base_url <> "/eurofxref-hist-90d.xml"
      _ -> base_url <> "/eurofxref-daily.xml"
    end
  end
end
