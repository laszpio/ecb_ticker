defmodule TickerTest do
  @moduledoc """
  Test suite for the Ticker module that handles ECB exchange rate data.
  Covers daily and historical rate fetching and parsing functionality.

  ## VCR Cassettes

  To re-record the cassettes:
  1. Delete the existing cassettes in fixture/vcr_cassettes/
  2. Set the required environment variables
  3. Run the tests
  """

  use ExUnit.Case, async: false  # async: false due to ExVCR
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Ticker

  import Ticker

  @moduletag :integration

  # Test data as module attributes
  @envelope """
  <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
    <gesmes:subject>Reference rates</gesmes:subject>
    <gesmes:Sender>
      <gesmes:name>European Central Bank</gesmes:name>
    </gesmes:Sender>
    <Cube>
      data container
    </Cube>
  </gesmes:Envelope>
  """

  @daily_data %{
    "-time" => "2019-03-20",
    "#content" => %{
      "Cube" => [
        %{"-currency" => "USD", "-rate" => "1.1354"},
        %{"-currency" => "IDR", "-rate" => "16082"}
      ]
    }
  }

  @historical_data [
    %{
      "-time" => "2019-03-20",
      "#content" => %{
        "Cube" => [
          %{"-currency" => "USD", "-rate" => "1.1354"},
          %{"-currency" => "IDR", "-rate" => "16082"}
        ]
      }
    },
    %{
      "-time" => "2019-03-21",
      "#content" => %{
        "Cube" => [
          %{"-currency" => "USD", "-rate" => "1.787"},
          %{"-currency" => "IDR", "-rate" => "16082.77"}
        ]
      }
    }
  ]

  setup_all do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    ExVCR.Config.filter_sensitive_data("sensitive-data", "FILTERED")
    :ok
  end

  describe "XML parsing" do
    test "returns response XML's envelope" do
      {:ok, response} = parse_response_body(@envelope)
      assert response |> Map.get("Cube") == "data container",
             "Expected envelope to contain data container"
    end
  end

  describe "rate extraction" do
    test "extracts rates' date" do
      assert extract_rates(@daily_data) |> Map.get(:date) == ~D[2019-03-20]
    end

    test "rates are based to EUR" do
      assert extract_rates(@daily_data) |> Map.get(:base) == "EUR"
    end

    test "extracts rates for all currencies" do
      rates = extract_rates(@daily_data) |> Map.get(:rates)
      assert rates == [
               {"USD", 1.1354},
               {"IDR", 16_082.0}
             ]
      Enum.each(rates, &assert_valid_currency_rate/1)
    end

    test "extracts rates for all days in historical feed" do
      result = extract_rates(@historical_data)
      assert_historical_rates(result)
    end
  end

  describe "endpoints" do
    @feed_base "https://www.ecb.europa.eu/stats/eurofxref"

    test "returns daily ECB feed url" do
      assert endpoint_url(:daily) == @feed_base <> "/eurofxref-daily.xml"
    end

    test "returns historical (90 days) feed url" do
      assert endpoint_url(:historical) == @feed_base <> "/eurofxref-hist-90d.xml"
    end
  end

  describe "API integration" do
    test "returns daily currency rates" do
      use_cassette "ebc_exchangerates_daily" do
        result = daily()

        assert is_map(result), "Expected result to be a map"
        assert result[:date] == ~D[2025-05-23]

        rates = result[:rates]
        assert_rates_structure(rates)
      end
    end

    test "returns historical currency rates" do
      use_cassette "ebc_exchangerates_90d" do
        result = historical()

        assert is_list(result), "Expected result to be a list"
        assert length(result) == 62, "Expected 62 days of historical data"

        Enum.each(result, fn daily ->
          assert Map.has_key?(daily, :date), "Each entry should have a date"
          assert_rates_structure(daily[:rates])
        end)
      end
    end
  end

  # Helper functions
  defp assert_valid_currency_rate({currency, rate}) do
    assert is_binary(currency) and byte_size(currency) == 3,
           "Currency code should be 3 characters"
    assert is_float(rate) and rate > 0,
           "Rate should be a positive float"
  end

  defp assert_rates_structure(rates) do
    assert is_list(rates), "Rates should be a list"
    assert length(rates) == 30, "Expected 30 currency rates"
    Enum.each(rates, &assert_valid_currency_rate/1)
  end

  defp assert_historical_rates(results) do
    assert results == [
             %{
               base: "EUR",
               date: ~D[2019-03-20],
               rates: [
                 {"USD", 1.1354},
                 {"IDR", 16_082.0}
               ]
             },
             %{
               base: "EUR",
               date: ~D[2019-03-21],
               rates: [
                 {"USD", 1.787},
                 {"IDR", 16_082.77}
               ]
             }
           ]
  end
end
