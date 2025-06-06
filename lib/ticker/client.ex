defmodule Ticker.Client do
  @moduledoc """
  Handles HTTP communication with the European Central Bank API.
  """

  @base_url "https://www.ecb.europa.eu/stats/eurofxref"

  @doc """
  Fetches data from the ECB API based on the feed type.
  """
  @spec fetch(atom()) :: {:ok, String.t()} | {:error, any()}
  def fetch(feed) do
    Tesla.get(endpoint_url(feed))
    |> handle_response()
  end

  @doc """
  Builds a URL to ECB currency API.

  Data feeds:
    - :daily returns URL for latest published exchange rates
    - :historical returns URL for exchange rates published within last 90 days
  """
  @spec endpoint_url(atom()) :: String.t()
  def endpoint_url(feed) do
    case feed do
      :historical -> @base_url <> "/eurofxref-hist-90d.xml"
      _ -> @base_url <> "/eurofxref-daily.xml"
    end
  end

  defp handle_response({:ok, %{body: body, status: status}}) when status in 200..299 do
    {:ok, body}
  end

  defp handle_response({:ok, %{status: status}}) do
    {:error, "HTTP request failed with status code: #{status}"}
  end

  defp handle_response({:error, reason}) do
    {:error, reason}
  end
end
