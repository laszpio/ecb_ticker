defmodule Ticker.Parser do
  @moduledoc """
  Handles parsing of XML responses from the ECB API and extraction of exchange rate data.
  """

  @base_currency "EUR"

  @doc """
  Parses XML response body and returns data container.
  """
  @spec parse_xml(String.t()) :: {:ok, map()} | {:error, any()}
  def parse_xml(xml) do
    case XmlToMap.naive_map(xml) do
      %{"gesmes:Envelope" => data} -> {:ok, data}
      {:error, message} -> {:error, message}
      _ -> {:error, :invalid_response_format}
    end
  end

  @doc """
  Extracts exchange rates from the parsed data structure.
  """
  @spec extract_rates(map() | list()) :: Ticker.Types.rates_result() | [Ticker.Types.rates_result()]
  def extract_rates(data) when is_map(data) do
    %{
      base: @base_currency,
      date: rates_date(data),
      rates: Enum.map(data |> get_in(["#content", "Cube"]), &currency_rate/1)
    }
  end

  def extract_rates(data) when is_list(data) do
    Enum.map(data, &extract_rates/1)
  end

  @doc """
  Processes the response data by extracting the Cube data and transforming it.
  """
  @spec process_response_data(map()) :: Ticker.Types.rates_result() | [Ticker.Types.rates_result()]
  def process_response_data(data) do
    data |> get_in(["Cube", "Cube"]) |> extract_rates()
  end

  defp rates_date(data) do
    {:ok, date} = data |> Map.fetch!("-time") |> Date.from_iso8601()
    date
  rescue
    e in [KeyError, ArgumentError] ->
      reraise "Failed to parse date: #{inspect(e.message)}", __STACKTRACE__
  end

  defp currency_rate(data) do
    with {:ok, currency} <- Map.fetch(data, "-currency"),
         {:ok, rate_str} <- Map.fetch(data, "-rate"),
         {rate, _} <- Float.parse(rate_str) do
      {currency, rate}
    else
      :error ->
        raise KeyError, "Required currency data missing in #{inspect(data)}"
      _ ->
        raise ArgumentError, "Invalid rate format in #{inspect(data)}"
    end
  end
end
