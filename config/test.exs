use Mix.Config

config :phoenix, Raftex.Router,
  http: [port: System.get_env("PORT") || 4001],
  catch_errors: false
