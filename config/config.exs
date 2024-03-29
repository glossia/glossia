# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :glossia,
  ecto_repos: [Glossia.Repo]

# Configures the endpoint
config :glossia, GlossiaWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [
      html: GlossiaWeb.Controllers.ErrorHTML,
      json: GlossiaWeb.Controllers.ErrorJSON
    ]
  ],
  pubsub_server: Glossia.PubSub,
  reloadable_compilers: [:phoenix] ++ Mix.compilers()

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :glossia, Glossia.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.19.4",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Oban
config :glossia, Oban,
  repo: Glossia.Repo,
  notifier: Oban.Notifiers.PG,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, builds: 50],
  shutdown_grace_period: :timer.minutes(3)

# Ueberauth
config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email"]}
  ]

config :glossia, :env, Mix.env()

config :tesla, :adapter, {Tesla.Adapter.Finch, name: Glossia.Finch}
config :oauth2, adapter: {Tesla.Adapter.Finch, name: Glossia.Finch}

config :glossia, :open_graph_metadata, %{
  title: "Glossia",
  description: "AI Localization on Autopilot. Experience localization like never before.",
  keywords: [
    "l10n",
    "i18n",
    "openai",
    "localization",
    "translation",
    "ai",
    "machine translation",
    "machine learning",
    "neural machine translation",
    "llm",
    "glossia"
  ],
  domain: "glossia.ai",
  base_url: "https://glossia.ai" |> URI.parse(),
  github_url: "https://github.com/glossia",
  language: "en-us",
  twitter_handle: "@glossiaai",
  author: "Glossia"
}

config :glossia, Glossia.Repo, migration_primary_key: [name: :id, type: :binary_id]

config :mime, :types, %{
  "application/typescript" => ["ts"]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
