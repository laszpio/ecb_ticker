defmodule TickerTest do
  use ExUnit.Case
  doctest Ticker

  import Ticker

  test "returns response XML's envelope" do
    envelope = File.read!("test/eurofxref-envelope.xml")
    {:ok, response} = parse_response_body(envelope)

    assert response |> Map.get("Cube") == "data container"
  end

  @daily %{
    "time" => "2019-03-20",
    "Cube" => [
      %{"currency" => "USD", "rate" => "1.1354"},
      %{"currency" => "IDR", "rate" => "16082"}
    ]
  }

  test "extracts rates' date" do
    assert extract_rates(@daily) |> Map.get(:date) == "2019-03-20"
  end

  test "extracts rates for all currencies" do
    assert extract_rates(@daily) |> Map.get(:rates) == [
             {"USD", 1.1354},
             {"IDR", 16082.0}
           ]
  end

  @historic [
    %{
      "time" => "2019-03-20",
      "Cube" => [
        %{"currency" => "USD", "rate" => "1.1354"},
        %{"currency" => "IDR", "rate" => "16082"}
      ]
    },
    %{
      "time" => "2019-03-21",
      "Cube" => [
        %{"currency" => "USD", "rate" => "1.787"},
        %{"currency" => "IDR", "rate" => "16082.77"}
      ]
    }
  ]

  test "extracts rates for all dail in historic feed" do
    assert extract_rates(@historic) == [
             %{
               date: "2019-03-20",
               rates: [
                 {"USD", 1.1354},
                 {"IDR", 16082.0}
               ]
             },
             %{
               date: "2019-03-21",
               rates: [
                 {"USD", 1.787},
                 {"IDR", 16082.77}
               ]
             }
           ]
  end
end
