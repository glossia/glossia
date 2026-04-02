# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :glossia,
  ecto_repos: [Glossia.Repo, Glossia.IngestRepo],
  generators: [timestamp_type: :utc_datetime]

config :ecto_ch,
  default_table_engine: "MergeTree"

config :glossia, Glossia.Repo, migration_primary_key: [name: :id, type: :binary_id]

# Configure the endpoint
config :glossia, GlossiaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: GlossiaWeb.ErrorHTML, json: GlossiaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Glossia.PubSub,
  live_view: [signing_salt: "mUXrjioL"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :glossia, Glossia.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  glossia: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :trace_id, :span_id]

config :sentry,
  dsn: nil,
  environment_name: config_env(),
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

config :glossia, :sentry_dsn_js, nil

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# OAuth providers (configured at runtime via runtime.exs from env vars)
config :glossia, :oauth_providers, []

# Boruta OAuth2 provider
config :boruta, Boruta.Oauth,
  repo: Glossia.Repo,
  issuer: "http://localhost:4050",
  contexts: [
    resource_owners: Glossia.OAuth.ResourceOwners
  ]

config :glossia, Glossia.Stripe,
  enabled: false,
  price_id: nil,
  webhook_secret: nil

config :glossia, Glossia.Github, webhook_secret: nil
config :glossia, Glossia.Gitlab, webhook_secret: nil

config :glossia, Glossia.PromEx,
  manual_metrics_start_delay: :no_delay,
  grafana: :disabled

config :glossia, GlossiaWeb.Plugs.Metrics, bearer_token: nil

config :glossia, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.PG,
  repo: Glossia.Repo,
  queues: [default: 10]

config :glossia, GlossiaWeb.Plugs.OpsAuth, username: "ops", password: nil

config :ex_aws,
  json_codec: JSON

config :glossia, Glossia.Storage, bucket: "glossia"

config :flop, repo: Glossia.Repo

config :glossia, Glossia.OgImage, enabled: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
