# EBC Ticker

[![Build Status](https://travis-ci.com/laszpio/ecb_ticker.svg?branch=master)](https://travis-ci.com/laszpio/ecb_ticker)

Provides current and historical (90 days) foreign exchange rates published by the [European Central Bank](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html).

The reference rates are usually updated around 16:00 CET on every working day,
except on [TARGET](https://www.ecb.europa.eu/home/contacts/working-hours/html/index.en.html)
closing days. They are based on a regular daily concertation procedure between
central banks across Europe, which normally takes place at 14:15 CET.

## Daily

```elixir
Ticker.daily()
```

Sample result:

```elixir
%{
  date: ~D[2019-04-01],
  rates: [
    {"USD", 1.1236},
    {"JPY", 124.68},
    {"BGN", 1.9558},
    {"CZK", 25.791},
    {"DKK", 7.4641},
    {"GBP", 0.85658},
    {"HUF", 321.04},
    {"PLN", 4.299},
    {"RON", 4.7626},
    {"SEK", 10.42},
    {"CHF", 1.118},
    {"ISK", 137.7},
    {"NOK", 9.638},
    {"HRK", 7.4268},
    {"RUB", 73.7449},
    {"TRY", 6.2135},
    {"AUD", 1.5775},
    {"BRL", 4.3564},
    {"CAD", 1.5006},
    {"CNY", 7.541},
    {"HKD", 8.8201},
    {"IDR", 15983.21},
    {"ILS", 4.0746},
    {"INR", 77.8885},
    {"KRW", 1275.24},
    {"MXN", 21.6437},
    {"MYR", 4.5848},
    {"NZD", 1.6458},
    {"PHP", 58.972},
    {"SGD", 1.5213},
    {"THB", 35.657},
    {"ZAR", 15.9175}
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
