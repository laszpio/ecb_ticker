import Config

config :tesla, adapter: Tesla.Adapter.Hackney

config :logger, :console,
       metadata: [:request_id]
