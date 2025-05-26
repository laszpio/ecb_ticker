defmodule Ticker.Types do
  @moduledoc """
  Type specifications for the Ticker application.
  """

  @typedoc "Currency code and rate pair"
  @type rate :: {String.t(), float()}

  @typedoc "Exchange rates for a specific date"
  @type rates_result :: %{base: String.t(), date: Date.t(), rates: [rate()]}

  @typedoc "Error result"
  @type error :: {:error, any()}

  @typedoc "Function result type"
  @type result :: rates_result() | [rates_result()] | error()
end
