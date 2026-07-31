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

# Keep English as the source-language fallback and default Gettext locale.
config :glossia, GlossiaWeb.Gettext, default_locale: "en"

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
noora_static_path = Path.expand("../deps/noora/priv/static", __DIR__)

config :esbuild,
  version: "0.25.4",
  glossia: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.) ++
        [
          "--alias:noora=#{noora_static_path}/noora.js"
        ],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ],
  noora: [
    args:
      ~w(css/noora.css --bundle --target=es2022 --outfile=../priv/static/assets/noora.css --external:/fonts/* --external:/images/*) ++
        [
          "--alias:noora/noora.css=#{noora_static_path}/noora.css"
        ],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ],
  glossia_web: [
    args:
      ~w(#{Path.expand("../../sdk/web/src/index.ts", __DIR__)} --bundle --format=iife --global-name=glossia --target=es2020 --outfile=../priv/static/assets/glossia-web.js),
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

config :glossia, :event_handler, Glossia.Analytics.Smolanalytics

config :glossia, Glossia.Analytics.Smolanalytics,
  enabled: false,
  url: nil,
  write_key: nil,
  environment: to_string(config_env()),
  request_options: []

# Website analytics ingestion. `identity_secret` salts the daily-rotated visitor
# hash (see `Glossia.Analytics.Identity`); it is overridden per-environment below.
config :glossia, Glossia.Analytics,
  enabled: true,
  geolocation: [adapter: Glossia.Analytics.Geolocation.Noop]

# Dogfooding: when `domain` is set, the root layout renders the Glossia web
# analytics snippet on every page so Glossia measures itself.
config :glossia, :web_analytics, domain: nil

# User-Agent classification (device/browser/OS). The regex database lives under
# `priv/ua_inspector` and is downloaded via `mix ua_inspector.download`; the
# release overrides the path to the app's priv dir in `runtime.exs`.
config :ua_inspector,
  database_path: "priv/ua_inspector",
  startup_silent: true

config :glossia, Glossia.PromEx,
  manual_metrics_start_delay: :no_delay,
  grafana: :disabled

config :glossia, GlossiaWeb.Plugs.Metrics, bearer_token: nil

config :glossia, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.PG,
  repo: Glossia.Repo,
  queues: [default: 10, analytics: 5],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/10 * * * *", Glossia.Projects.SetupPullRequestSyncWorker}
     ]}
  ]

config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: Glossia.Repo

config :fun_with_flags, :cache_bust_notifications,
  enabled: true,
  adapter: FunWithFlags.Notifications.PhoenixPubSub,
  client: Glossia.PubSub

config :ex_aws,
  json_codec: JSON

config :glossia, Glossia.Storage, bucket: "glossia"

config :flop, repo: Glossia.Repo

config :glossia, Glossia.OgImage, enabled: true

config :glossia, Glossia.Sandbox,
  adapter: Glossia.Sandbox.ClusterAdapter,
  enabled: true,
  max_active_per_account: 3,
  default_ttl_seconds: 3600,
  command_timeout_ms: 120_000,
  output_limit_bytes: 256_000,
  reaper_enabled: true,
  reaper_interval_ms: 60_000,
  delete_retry_after_ms: 60_000,
  microsandbox_command: "msb",
  microsandbox_image: "glossia-local:dev",
  microsandbox_cpus: 2,
  microsandbox_memory: "2G",
  microsandbox_repo_path: "/tmp/glossia/repo"

config :glossia, Glossia.Projects.Setup,
  minimax_api_key: nil,
  harness: "opencode",
  harness_command: "opencode",
  harness_model: nil,
  harness_agent: nil,
  harness_pure: true,
  harness_env: %{},
  harness_context_path: nil,
  opencode_config: %{}

config :glossia, Glossia.Projects.SetupRecovery, enabled: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
