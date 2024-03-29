import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

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
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :glossia, GlossiaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dmkN1FpDS+crh8zsf6cPY9Psdg+WVeDRh+NDJ0NkbIj2omW0K6nc3DBbV2u0VJXl",
  server: false

# In test we don't send emails.
config :glossia, Glossia.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Oban
config :glossia, Oban, testing: :inline

# exvcr
config :exvcr,
  vcr_cassette_library_dir: "test/support/vcr_cassettes",
  filter_sensitive_data: [
    [pattern: "<PASSWORD>.+</PASSWORD>", placeholder: "PASSWORD_PLACEHOLDER"]
  ],
  filter_url_params: false,
  filter_request_headers: ["Authorization"],
  response_headers_blacklist: []
