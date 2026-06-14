# ECB Ticker

[![Build Status](https://github.com/laszpio/ecb_ticker/actions/workflows/elixir-ci.yml/badge.svg)](https://github.com/laszpio/ecb_ticker/actions/workflows/elixir-ci.yml)

Provides current and historical (90 days) foreign exchange rates published by the [European Central Bank](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html).

> The reference rates are usually updated around 16:00 CET on every working day,
> except on [TARGET](https://www.ecb.europa.eu/home/contacts/working-hours/html/index.en.html)
> closing days. They are based on a regular daily concertation procedure between
> central banks across Europe, which normally takes place at 14:15 CET.

## Testing

Run the test suite:

```bash
mix test
```

### VCR Cassettes

HTTP interactions with the ECB API are recorded using [ExVCR](https://github.com/parroty/exvcr) and stored as JSON fixtures in `fixture/vcr_cassettes/`. Tests replay these recorded responses instead of making live network requests, keeping the suite fast and deterministic.

| Cassette | Covers |
|---|---|
| `daily_rates.json` | `Ticker.daily/0` |
| `historical_rates.json` | `Ticker.historical/0` |

To re-record the cassettes against the live ECB API (e.g. after a schema change or to refresh stale data):

```bash
rm fixture/vcr_cassettes/*.json
mix test
```

ExVCR will make real HTTP requests on the next run and save the responses as new cassettes. Commit the updated files afterwards.

## Daily

```elixir
Ticker.daily()
```

Sample result:

```elixir
%{
  base: "EUR",
  date: ~D[2022-03-08],
  rates: [
    {"USD", 1.0892},
    {"JPY", 126.03},
    {"BGN", 1.9558},
    {"CZK", 25.642},
    {"DKK", 7.4441},
    {"GBP", 0.83185},
    {"HUF", 388.28},
    {"PLN", 4.9103},
    {"RON", 4.9494},
    {"SEK", 10.8803},
    {"CHF", 1.0111},
    {"ISK", 145.9},
    {"NOK", 9.7925},
    {"HRK", 7.5715},
    {"TRY", 15.8183},
    {"AUD", 1.4971},
    {"BRL", 5.5346},
    {"CAD", 1.3978},
    {"CNY", 6.8805},
    {"HKD", 8.5183},
    {"IDR", 15639.76},
    {"ILS", 3.6022},
    {"INR", 83.924},
    {"KRW", 1344.71},
    {"MXN", 23.2866},
    {"MYR", 4.5556},
    {"NZD", 1.5958},
    {"PHP", 56.9},
    {"SGD", 1.4856},
    {"THB", 36.156},
    {"ZAR", 16.7051}
  ]
}
```

## Historical (last 90 days)

```elixir
Ticker.historical()
```

Sample result:

```elixir
[
  %{
    date: ~D[2019-04-01],
    rates: [
      {"USD", 1.1236},
      {"JPY", 124.68},
      ...
      {"ZAR", 15.9175}
    ]
  },
  %{
    date: ~D[2019-03-29],
    rates: [
      {"USD", 1.1235},
      {"JPY", 124.45},
      ...
      {"ZAR", 16.2642}
    ]
  },
  %{...},
  ...
]
```
