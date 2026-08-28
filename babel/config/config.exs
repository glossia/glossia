import Config

config :babel,
  ecto_repos: [Babel.Repo],
  generators: [timestamp_type: :utc_datetime]

config :babel, BabelWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BabelWeb.ErrorHTML, json: BabelWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Babel.PubSub,
  live_view: [signing_salt: "8KTbw9dE"]

config :babel, BabelWeb.Plugs.PomeriumAuth, enabled: false

noora_static_path = Path.expand("../deps/noora/priv/static", __DIR__)

config :esbuild,
  version: "0.25.4",
  babel: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*) ++
        ["--alias:noora=#{noora_static_path}/noora.js"],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ],
  noora: [
    args:
      ~w(css/noora.css --bundle --target=es2022 --outfile=../priv/static/assets/noora.css --external:/fonts/* --external:/images/*) ++
        ["--alias:noora/noora.css=#{noora_static_path}/noora.css"],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
