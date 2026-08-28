import Config

config :babel, Babel.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "babel_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :babel, BabelWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4060],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "Gj2se8qHXrpdrZyVJpMdhCIVhpduHOy+rHHudZPFHFSf48qUMsSqvkzyyA/bAImU",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:babel, ~w(--sourcemap=inline --watch)]},
    esbuild_noora: {Esbuild, :install_and_run, [:noora, ~w(--sourcemap=inline --watch)]}
  ]

config :babel, BabelWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r/priv\/static\/(?!uploads\/).*\.(js|css|png|jpeg|jpg|gif|svg)$/,
      ~r/priv\/gettext\/.*\.po$/,
      ~r/lib\/babel_web\/(controllers|live|components)\/.*\.(ex|heex)$/
    ]
  ]

config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true
