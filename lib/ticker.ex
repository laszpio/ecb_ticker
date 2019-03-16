defmodule Ticker do
  @moduledoc """
  European Central Bank current foregin exchange rates.
  """

  @endpoint "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"

  def query do
    case HTTPotion.get(@endpoint) do
      %HTTPotion.Response{body: body, status_code: 200} ->
        case body |> parse_response_body do
          {:ok, response} -> process_response(response) |> display_ticker
        end

      %HTTPotion.ErrorResponse{message: message} ->
        {:error, message}
    end
  end

  defp parse_response_body(response) do
    {:ok, XmlToMap.naive_map(response)}
  end

  defp process_response(response) do
    [tree | _] = response |> Map.values()
    tree = tree |> Map.get("Cube") |> Map.get("Cube")

    %{
      date: tree["time"],
      rates: Enum.map(tree["Cube"], fn r -> {r["currency"], r["rate"] |> String.to_float()} end)
    }
  end

  defp display_ticker(data) do
    currency_base = data["base"]
    date = data["date"]

    IO.puts("European Central Bank exchange of #{currency_base} on #{date}:")
    display_currency_rates(data)
  end

  defp display_currency_rates(data) do
    Enum.each(data[:rates], fn rate ->
      IO.puts("#{rate |> elem(0)} | #{rate |> elem(1)}")
    end)
  end
end
