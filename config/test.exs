import Config

config :logger, :default_formatter, metadata: [:key_new]

config :logger, :console, metadata: [:key_old]
