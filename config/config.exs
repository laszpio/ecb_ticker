import Config

config :tesla, adapter: Tesla.Adapter.Hackney
config :tesla, disable_deprecated_builder_warning: true

config :logger, :console,
       metadata: [:request_id]
