defmodule Ticker do
  @moduledoc """
  European Central Bank current foregin exchange rates.
  """

  @endpoint "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"

  def query do
    case HTTPotion.get(@endpoint) do
      %HTTPotion.Response{body: body, status_code: 200} ->
        case body |> parse_response_body do
          {:ok, response} -> process_response_data(response)
          {:error, message} -> message
        end

      %HTTPotion.ErrorResponse{message: message} ->
        {:error, message}
    end
  end

  defp parse_response_body(response) do
    case XmlToMap.naive_map(response) do
      %{"{http://www.gesmes.org/xml/2002-08-01}Envelope" => data} -> {:ok, data}
      {:error, message} -> {:error, message}
    end
  end

  defp process_response_data(data) do
    data = data |> Map.get("Cube") |> Map.get("Cube")

    %{
      date: data["time"],
      rates: Enum.map(data["Cube"], fn r -> {r["currency"], r["rate"] |> String.to_float()} end)
    }
  end
end
