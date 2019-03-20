defmodule TickerTest do
  use ExUnit.Case
  doctest Ticker

  import Ticker

  test "returns response XML's envelope" do
    envelope = File.read!("test/eurofxref-envelope.xml")
    {:ok, response} = parse_response_body(envelope)

    assert response |> Map.get("Cube") == "data container"
  end
end
