import Config
import Dotenvy

source(["#{config_env()}.env", "#{config_env()}.override.env", ".env", System.get_env()])

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/glossia start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :glossia, GlossiaWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :glossia, Glossia.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :glossia, GlossiaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :glossia, GlossiaWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :glossia, GlossiaWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :glossia, Glossia.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :posthog,
    api_url: env!("POSTHOG_API_URL", :string),
    api_key: env!("POSTHOG_API_KEY", :string)

  # App Signal
  config :appsignal, :config,
    otp_app: :glossia,
    name: "glossia",
    push_api_key: env!("APP_SIGNAL_PUSH_API_KEY", :string),
    env: :prod

  # Glossia Production Variables
  config :glossia,
    google_application_credentials_json_base_64:
      env!("GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE_64", :string, ""),
    google_cloud_project_id: env!("GOOGLE_CLOUD_PROJECT_ID", :string, ""),
    app_signal_builder_api_key: env!("APP_SIGNAL_BUILDER_API_KEY", :string, "")
end

# Glossia
config :glossia,
  github_app_webhooks_secret: env!("GITHUB_APP_WEBHOOKS_SECRET", :string, ""),
  github_app_id: env!("GITHUB_APP_ID", :string, ""),
  builder_api_key: env!("BUILDER_API_KEY", :string, ""),
  url: if(config_env() == :prod, do: "https://glossia.ai", else: "http://127.0.0.1:4000")

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: env!("GITHUB_APP_CLIENT_ID", :string, ""),
  client_secret: env!("GITHUB_APP_CLIENT_SECRET", :string, "")

# Joken

config :joken,
  github: [
    signer_alg: "RS256",
    key_pem: env!("GITHUB_APP_PRIVATE_KEY_BASE_64", :string, "") |> Base.decode64!()
  ],
  project: env!("BUILD_JWT_SIGNING_KEY", :string, "")

config :glossia, GlossiaWeb.Endpoint,
  live_view: [
    signing_salt:
      env!(
        "LIVE_VIEW_SIGNING_SALT",
        :string,
        "Eq/DO4cJ5lnv1Ykf5wW9+k4q/jJl9/bV0EJV/ZIJVlJoavWu7w7Yl6Y8jmPEK2Ks"
      )
  ]

config :glossia, GlossiaWeb.Endpoint,
  secret_key_base:
    env!(
      "SECRET_KEY_BASE",
      :string,
      "Wsi8PTaGsZV1pYCP/AfGtpByH12WDCofgiFVGDfk7iMCWUN5mwSgkSBYrQNIOdZ7"
    )
