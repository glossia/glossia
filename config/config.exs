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
  url: [host: "localhost"],
  render_errors: [
    formats: [html: GlossiaWeb.ErrorHTML, json: GlossiaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Glossia.PubSub,
  live_view: [
    signing_salt:
      System.get_env("LIVE_VIEW_SIGNING_SALT") ||
        "Eq/DO4cJ5lnv1Ykf5wW9+k4q/jJl9/bV0EJV/ZIJVlJoavWu7w7Yl6Y8jmPEK2Ks"
  ]

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
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Oban
config :glossia, Oban,
  repo: Glossia.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10]

# Ueberauth
config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email"]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_APP_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_APP_CLIENT_SECRET")

config :glossia, :env, Mix.env()
