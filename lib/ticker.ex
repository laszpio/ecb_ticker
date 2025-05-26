defmodule Ticker do
  @moduledoc """
  Provides current and historical (90 days) foreign exchange rates published by the
  [European Central Bank](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html).
  """

  alias Ticker.{Client, Parser, Types}

  @doc """
  Provides daily exchange rates.

  Returns a map with base currency, date, and list of currency rates.

  ## Example output format:

      %{
        base: "EUR",
        date: ~D[2022-03-08],
        rates: [{"USD", 1.0892}, {"JPY", 126.03}, ...]
      }
  """
  @spec daily() :: Types.result()
  def daily, do: query(:daily)

  @doc """
  Provides historical 90 days exchange rates.

  Returns a list of maps, each containing base currency, date, and rates for that date.

  ## Example output format:

      [
        %{base: "EUR", date: ~D[2022-03-08], rates: [{"USD", 1.0892}, {"JPY", 126.03}, ...]},
        %{base: "EUR", date: ~D[2022-03-07], rates: [{"USD", 1.0854}, {"JPY", 125.45}, ...]},
        # ...
      ]
  """
  @spec historical() :: Types.result()
  def historical, do: query(:historical)

  # Public functions for backward compatibility and testing

  @doc """
  Parses XML response body and returns data container.

  ## Examples

      iex> xml = "<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?>
      ...> <gesmes:Envelope xmlns:gesmes=\\"http://www.gesmes.org/xml/2002-08-01\\" xmlns=\\"http://www.ecb.int/vocabulary/2002-08-01/eurofxref\\">
      ...>   <gesmes:subject>Reference rates</gesmes:subject>
      ...>   <Cube>
      ...>     <Cube time=\\"2022-03-08\\">
      ...>       <Cube currency=\\"USD\\" rate=\\"1.0892\\"/>
      ...>     </Cube>
      ...>   </Cube>
      ...> </gesmes:Envelope>"
      iex> {:ok, result} = Ticker.parse_response_body(xml)
      iex> is_map(result)
      true
  """
  @spec parse_response_body(String.t()) :: {:ok, map()} | {:error, any()}
  def parse_response_body(xml), do: Parser.parse_xml(xml)

  @doc """
  Extracts rates from data container.

  ## Examples

      iex> data = %{"-time" => "2022-03-08", "#content" => %{"Cube" => [%{"-currency" => "USD", "-rate" => "1.0892"}]}}
      iex> result = Ticker.extract_rates(data)
      iex> result.base
      "EUR"
      iex> result.date
      ~D[2022-03-08]
      iex> length(result.rates)
      1
      iex> List.first(result.rates)
      {"USD", 1.0892}
  """
  @spec extract_rates(map() | list()) :: Types.rates_result() | [Types.rates_result()]
  def extract_rates(data), do: Parser.extract_rates(data)

  @doc """
  Builds a URL to ECB currency API.

  ## Examples

      iex> Ticker.endpoint_url(:daily)
      "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"

      iex> Ticker.endpoint_url(:historical)
      "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml"
  """
  @spec endpoint_url(atom()) :: String.t()
  def endpoint_url(feed), do: Client.endpoint_url(feed)

  # Private functions

  @spec query(atom()) :: Types.result()
  defp query(scope) do
    with {:ok, body} <- Client.fetch(scope),
         {:ok, data} <- Parser.parse_xml(body) do
      Parser.process_response_data(data)
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
