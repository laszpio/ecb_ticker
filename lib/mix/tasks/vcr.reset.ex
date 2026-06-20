defmodule Mix.Tasks.Vcr.Reset do
  @shortdoc "Delete recorded VCR cassettes so they are re-recorded on the next test run"

  @moduledoc """
  Deletes the VCR cassettes that were recorded against the live ECB API,
  causing ExVCR to make real HTTP requests and save fresh cassettes on the
  next `mix test` run.

  Only the two recorded cassettes are removed. Hand-crafted error fixtures
  (`daily_rates_500.json`, `daily_rates_network_error.json`) are left intact
  because they simulate responses the live API never returns and cannot be
  re-recorded automatically.

  ## Usage

      mix vcr.reset

  After running this task, execute `mix test` to re-record the cassettes,
  then commit the updated files.
  """

  use Mix.Task

  @cassette_dir "fixture/vcr_cassettes"

  @recorded_cassettes [
    "daily_rates.json",
    "historical_rates.json"
  ]

  @impl Mix.Task
  def run(_args) do
    Enum.each(@recorded_cassettes, fn filename ->
      path = Path.join(@cassette_dir, filename)

      if File.exists?(path) do
        File.rm!(path)
        Mix.shell().info("Deleted #{path}")
      else
        Mix.shell().info("Skipped #{path} (not found)")
      end
    end)

    Mix.shell().info("\nRun `mix test` to re-record cassettes against the live ECB API.")
  end
end
