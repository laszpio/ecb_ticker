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
    try do
      case XmlToMap.naive_map(xml) do
        %{"gesmes:Envelope" => data} -> {:ok, data}
        {:error, message} -> {:error, message}
        _ -> {:error, :invalid_response_format}
      end
    catch
      :throw, {:error, reason} -> {:error, reason}
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
      rates: data |> get_in(["#content", "Cube"]) |> List.wrap() |> Enum.map(&currency_rate/1)
    }
  end

  def extract_rates(data) when is_list(data) do
    Enum.map(data, &extract_rates/1)
  end

  @doc """
  Processes the response data by extracting the Cube data and transforming it.
  """
  @spec process_response_data(map()) :: Ticker.Types.rates_result() | [Ticker.Types.rates_result()] | Ticker.Types.error()
  def process_response_data(data) do
    case get_in(data, ["Cube", "Cube"]) do
      nil -> {:error, :no_data}
      cube -> extract_rates(cube)
    end
  end

  defp rates_date(data) do
    with {:ok, time_str} <- Map.fetch(data, "-time"),
         {:ok, date} <- Date.from_iso8601(time_str) do
      date
    else
      :error -> raise KeyError, "Missing -time key in date data"
      {:error, reason} -> raise ArgumentError, "Invalid date string: #{inspect(reason)}"
    end
  end

  defp currency_rate(data) do
    with {:ok, currency} <- Map.fetch(data, "-currency"),
         {:ok, rate_str} <- Map.fetch(data, "-rate") do
      case Float.parse(rate_str) do
        {rate, _} -> {currency, rate}
        :error -> raise ArgumentError, "Invalid rate format in #{inspect(data)}"
      end
    else
      :error -> raise KeyError, "Required currency data missing in #{inspect(data)}"
    end
  end
end
