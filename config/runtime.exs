import Config
import Dotenvy

source([".env.#{config_env()}", "#{config_env()}.override.env", ".env", System.get_env()])

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
  config :glossia, Glossia.Application.Endpoint, server: true
end

if config_env() == :prod do
  # https://community.neon.tech/t/guide-on-connecting-via-ecto/75
  # https://neon.tech/docs/guides/elixir-ecto
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  %URI{host: database_host, userinfo: userinfo, path: path} = URI.parse(database_url)
  [database_username, database_password] = String.split(userinfo, ":")
  database = String.trim_leading(path, "/")

  database_ca_cert_filepath =
    System.get_env("DATABASE_CA_CERT_FILEPATH") || "deps/castore/priv/cacerts.pem"

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :glossia, Glossia.Foundation.Database.Core.Repo,
    database: database,
    hostname: database_host,
    username: database_username,
    password: database_password,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    ssl: true,
    ssl_opts: [
      verify: :verify_peer,
      cacertfile: database_ca_cert_filepath,
      # see https://pspdfkit.com/blog/2022/using-ssl-postgresql-connections-elixir/
      server_name_indication: to_charlist(database_host),
      customize_hostname_check: [
        # Our hosting provider uses a wildcard certificate. By default, Erlang does not support wildcard certificates. This function supports validating wildcard hosts
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]

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

  host = System.get_env("PHX_HOST") || "glossia.ai"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :glossia, Glossia.Application.Endpoint,
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
  #     config :glossia, Glossia.Application.Endpoint,
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
  #     config :glossia, Glossia.Application.Endpoint,
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

  posthog_api_url = env!("POSTHOG_API_URL", :string, "")
  posthog_api_key = env!("POSTHOG_API_KEY", :string, "")

  if posthog_api_url != "" && posthog_api_key != "" do
    config :posthog, api_url: posthog_api_url, api_key: posthog_api_key
  end

  # App Signal
  appsignal_api_key = env!("APP_SIGNAL_PUSH_API_KEY", :string, "")

  if appsignal_api_key != "" do
    config :appsignal, :config,
      otp_app: :glossia,
      name: "glossia",
      push_api_key: appsignal_api_key,
      env: :prod,
      active: true
  end

  appsignal_builder_api_key = env!("APP_SIGNAL_BUILDER_API_KEY", :string, "")

  if appsignal_builder_api_key != "" do
    config :glossia, app_signal_builder_api_key: env!("APP_SIGNAL_BUILDER_API_KEY", :string, "")
  end

  # Glossia Production Variables
  config :glossia,
    google_application_credentials_json_base_64:
      env!("GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE_64", :string, ""),
    google_cloud_project_id: env!("GOOGLE_CLOUD_PROJECT_ID", :string, "")
end

openai_chatgpt_secret_key = env!("OPENAI_CHATGPT_SECRET_KEY", :string, "")

if openai_chatgpt_secret_key == "" do
  raise "The required environment variable OPENAI_CHATGPT_SECRET_KEY is missing."
else
  config :glossia, openai_chatgpt_secret_key: openai_chatgpt_secret_key
end

# Glossia
config :glossia,
  github_app_webhooks_secret: env!("GITHUB_APP_WEBHOOKS_SECRET", :string, ""),
  github_app_id: env!("GITHUB_APP_ID", :string, ""),
  github_app_name: env!("GITHUB_APP_NAME", :string, ""),
  github_app_bot_user: env!("GITHUB_APP_BOT_USER", :string, ""),
  github_app_client_id: env!("GITHUB_APP_CLIENT_ID", :string, ""),
  github_app_client_secret: env!("GITHUB_APP_CLIENT_SECRET", :string, ""),
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

config :glossia, Glossia.Application.Endpoint,
  live_view: [
    signing_salt:
      env!(
        "LIVE_VIEW_SIGNING_SALT",
        :string,
        "Eq/DO4cJ5lnv1Ykf5wW9+k4q/jJl9/bV0EJV/ZIJVlJoavWu7w7Yl6Y8jmPEK2Ks"
      )
  ]

config :glossia, Glossia.Application.Endpoint,
  secret_key_base:
    env!(
      "SECRET_KEY_BASE",
      :string,
      "Wsi8PTaGsZV1pYCP/AfGtpByH12WDCofgiFVGDfk7iMCWUN5mwSgkSBYrQNIOdZ7"
    )

# Tentact
config :tentacat, :pagination, :auto
config :tentacat, :extra_headers, [{"X-GitHub-Api-Version", "2022-11-28"}]

# Stripe

plan = Application.get_env(:glossia, :plan)

if (plan == :cloud && config_env() == :prod) || config_env() == :dev do
  config :stripity_stripe, api_key: env!("STRIPE_API_KEY", :string?)
  config :glossia, :payments, premium_product_id: env!("STRIPE_PREMIUM_PRODUCT_ID", :string!)
end
