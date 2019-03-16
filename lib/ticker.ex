defmodule Ticker do
  @moduledoc """
  European Central Bank current foregin exchange rates.
  """

  @endpoint "https://api.exchangeratesapi.io/latest"

  def query do
    case HTTPotion.get(@endpoint) do
      %HTTPotion.Response{body: body, status_code: 200} ->
        case body |> parse_response_body do
          {:ok, response} -> display_ticker(response)
        end
    end
  end

  defp display_ticker(data) do
    currency_base = data["base"]
    date = data["date"]

    IO.puts("European Central Bank exchange of #{currency_base} on #{date}:")
    display_currency_rates(data)
  end

  defp parse_response_body(response) do
    Jason.decode(response)
  end

  defp display_currency_rates(data) do
    Enum.each(data["rates"], fn rate ->
      IO.puts("#{rate |> elem(0)} | #{rate |> elem(1)}")
    end)
  end
end
