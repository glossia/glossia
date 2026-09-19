import Config

config :babel, Babel.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "babel_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :babel, BabelWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4062],
  secret_key_base: "D6EA7yfgPvk0peEqmabB5i4szHOai8yKsnNCj0PiSkvW6eeNbiepi5WhCP19zY0q",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, enable_expensive_runtime_checks: true
config :phoenix, sort_verified_routes_query_params: true
config :babel, Oban, testing: :manual
