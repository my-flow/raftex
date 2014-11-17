# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the router
config :phoenix, Raftex.Router,
  url: [host: "localhost"],
  http: [port: System.get_env("PORT")],
  https: false,
  secret_key_base: "FzTDylF1pMXTz6sNErIsd3oXlrHkqc0sp7wGUHTuuYI7Mp5TDwoxRjAst4Qi8AQTlQoH4DWz+psGJr5UIr0UqQ==",
  catch_errors: true,
  debug_errors: false,
  error_controller: Raftex.PageController

# Session configuration
config :phoenix, Raftex.Router,
  session: [store: :cookie,
            key: "_raftex_key"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
