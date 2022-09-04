defmodule TickerTest do
  use ExUnit.Case
  doctest Ticker

  import Ticker
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

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

  test "returns response XML's envelope" do
    {:ok, response} = parse_response_body(@envelope)

    assert response |> Map.get("Cube") == "data container"
  end

  @daily %{
    "-time" => "2019-03-20",
    "#content" => %{
      "Cube" => [
        %{"-currency" => "USD", "-rate" => "1.1354"},
        %{"-currency" => "IDR", "-rate" => "16082"}
      ]
    }
  }

  test "extracts rates' date" do
    assert extract_rates(@daily) |> Map.get(:date) == ~D[2019-03-20]
  end

  test "rates are based to EUR" do
    assert extract_rates(@daily) |> Map.get(:base) == "EUR"
  end

  test "extracts rates for all currencies" do
    assert extract_rates(@daily) |> Map.get(:rates) == [
             {"USD", 1.1354},
             {"IDR", 16_082.0}
           ]
  end

  @historical [
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

  test "extracts rates for all dail in historical feed" do
    assert extract_rates(@historical) == [
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

  @feed_base "https://www.ecb.europa.eu/stats/eurofxref"

  test "returns daily EBC feed url" do
    assert endpoint_url(:daily) == @feed_base <> "/eurofxref-daily.xml"
  end

  test "returns historical (90 days) feed url" do
    assert endpoint_url(:historical) == @feed_base <> "/eurofxref-hist-90d.xml"
  end

  test "returns daily currency rates" do
    use_cassette "ebc_exchangerates_daily" do
      result = daily()

      assert is_map(result)
      assert result[:date] == ~D[2022-09-02]

      rates = result[:rates]
      assert is_list(rates)
      assert rates |> length() == 31

      Enum.each(rates, fn record ->
        {currency, rate} = record
        assert currency =~ ~r/[A-Z]{3}/
        assert rate |> is_float()
      end)

      usd = rates |> List.first()
      assert usd |> elem(0) == "USD"
      assert usd |> elem(1) > 0
    end
  end

  test "returns historical currency rates" do
    use_cassette "ebc_exchangerates_90d" do
      result = historical()

      assert is_list(result)
      assert length(result) == 65

      Enum.each(result, fn daily ->
        assert daily |> Map.has_key?(:date)

        assert is_list(daily[:rates])
        assert daily[:rates] |> length() >= 31

        Enum.each(daily[:rates], fn record ->
          {currency, rate} = record
          assert currency =~ ~r/[A-Z]{3}/
          assert is_float(rate)
        end)
      end)
    end
  end
end
