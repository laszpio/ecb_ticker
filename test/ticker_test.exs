defmodule TickerTest do
  use ExUnit.Case
  doctest Ticker

  # Setup VCR for HTTP request recording/playback
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    # Configure ExVCR
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    ExVCR.Config.filter_sensitive_data("your-sensitive-data", "FILTERED")

    # Ensure hackney is started
    Application.ensure_all_started(:hackney)
    :ok
  end

  describe "endpoint_url/1" do
    test "returns correct URL for daily rates" do
      url = Ticker.endpoint_url(:daily)
      assert url == "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
    end

    test "returns correct URL for historical rates" do
      url = Ticker.endpoint_url(:historical)
      assert url == "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml"
    end
  end

  describe "parse_response_body/1" do
    test "parses valid XML response" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
        <gesmes:subject>Reference rates</gesmes:subject>
        <gesmes:Sender>
          <gesmes:name>European Central Bank</gesmes:name>
        </gesmes:Sender>
        <Cube>
          <Cube time="2022-03-08">
            <Cube currency="USD" rate="1.0892"/>
            <Cube currency="JPY" rate="126.03"/>
          </Cube>
        </Cube>
      </gesmes:Envelope>
      """

      {:ok, result} = Ticker.parse_response_body(xml)
      assert is_map(result)
      assert get_in(result, ["Cube", "Cube", "-time"]) == "2022-03-08"
    end
  end

  describe "extract_rates/1" do
    test "extracts rates from map data" do
      data = %{
        "-time" => "2022-03-08",
        "#content" => %{
          "Cube" => [
            %{"-currency" => "USD", "-rate" => "1.0892"},
            %{"-currency" => "JPY", "-rate" => "126.03"}
          ]
        }
      }

      result = Ticker.extract_rates(data)

      assert result.base == "EUR"
      assert result.date == ~D[2022-03-08]
      assert length(result.rates) == 2
      assert List.keyfind(result.rates, "USD", 0) == {"USD", 1.0892}
      assert List.keyfind(result.rates, "JPY", 0) == {"JPY", 126.03}
    end

    test "extracts rates from list of data" do
      data = [
        %{
          "-time" => "2022-03-08",
          "#content" => %{
            "Cube" => [
              %{"-currency" => "USD", "-rate" => "1.0892"},
              %{"-currency" => "JPY", "-rate" => "126.03"}
            ]
          }
        },
        %{
          "-time" => "2022-03-07",
          "#content" => %{
            "Cube" => [
              %{"-currency" => "USD", "-rate" => "1.0854"},
              %{"-currency" => "JPY", "-rate" => "125.45"}
            ]
          }
        }
      ]

      result = Ticker.extract_rates(data)

      assert is_list(result)
      assert length(result) == 2

      [day1, day2] = result

      assert day1.date == ~D[2022-03-08]
      assert day2.date == ~D[2022-03-07]

      assert List.keyfind(day1.rates, "USD", 0) == {"USD", 1.0892}
      assert List.keyfind(day2.rates, "USD", 0) == {"USD", 1.0854}
    end
  end

  describe "daily/0" do
    test "returns daily exchange rates" do
      use_cassette "daily_rates" do
        result = Ticker.daily()

        assert is_map(result)
        assert result.base == "EUR"
        assert is_list(result.rates)

        # At least check that some common currencies are present
        currencies = Enum.map(result.rates, fn {currency, _rate} -> currency end)
        assert "USD" in currencies
        assert "JPY" in currencies
        assert "GBP" in currencies

        # Validate rate format
        {_currency, rate} = List.first(result.rates)
        assert is_float(rate)
      end
    end
  end

  describe "historical/0" do
    test "returns historical exchange rates" do
      use_cassette "historical_rates" do
        result = Ticker.historical()

        assert is_list(result)
        assert length(result) > 0

        first_day = List.first(result)
        assert is_map(first_day)
        assert first_day.base == "EUR"
        assert is_list(first_day.rates)

        # Validate rate format across multiple days
        Enum.each(result, fn day ->
          assert %{base: "EUR", date: %Date{}, rates: rates} = day
          assert is_list(rates)
          assert length(rates) > 0

          # Validate first rate in each day
          {currency, rate} = List.first(rates)
          assert is_binary(currency)
          assert is_float(rate)
        end)
      end
    end
  end
end
