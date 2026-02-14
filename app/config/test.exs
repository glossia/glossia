import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :glossia, Glossia.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "glossia_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :glossia, Glossia.ClickHouseRepo,
  hostname: "localhost",
  port: 8123,
  database: "glossia_test#{System.get_env("MIX_TEST_PARTITION")}",
  settings: [readonly: 1]

config :glossia, Glossia.IngestRepo,
  hostname: "localhost",
  port: 8123,
  database: "glossia_test#{System.get_env("MIX_TEST_PARTITION")}",
  flush_interval_ms: 5000,
  max_buffer_size: 100_000,
  pool_size: 5

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :glossia, GlossiaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qSsvrUWYZI7plNpHSFNvM/HoGGRZ+FIAyhrfEvxrIAH6OrdCSvfCBxO/Sa30L5UU",
  server: false

# In test we don't send emails
config :glossia, Glossia.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :glossia, Oban, testing: :inline
