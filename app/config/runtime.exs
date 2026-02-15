import Config

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

config :glossia, GlossiaWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4050"))]

stripe_secret_key = System.get_env("STRIPE_SECRET_KEY") || System.get_env("STRIPE_API_KEY")

stripe_price_id =
  System.get_env("STRIPE_PRICE_ID") || System.get_env("STRIPE_CHECKOUT_PRICE_ID")

stripe_webhook_secret = System.get_env("STRIPE_WEBHOOK_SECRET")
# Default for a single "usage credits" meter. Create the Stripe meter with
# this same event name (in both test + live modes).
stripe_meter_event_name =
  System.get_env("STRIPE_METER_EVENT_NAME") ||
    "glossia_usage_credits"

stripe_enabled =
  case System.get_env("STRIPE_ENABLED") do
    "true" ->
      true

    "1" ->
      true

    "false" ->
      false

    "0" ->
      false

    _ ->
      is_binary(stripe_secret_key) and stripe_secret_key != "" and
        is_binary(stripe_price_id) and stripe_price_id != ""
  end

config :stripity_stripe, api_key: stripe_secret_key

config :glossia, Glossia.Stripe,
  enabled: stripe_enabled,
  price_id: stripe_price_id,
  webhook_secret: stripe_webhook_secret,
  meter_event_name: stripe_meter_event_name

github_webhook_secret = System.get_env("GITHUB_WEBHOOK_SECRET")
gitlab_webhook_secret = System.get_env("GITLAB_WEBHOOK_SECRET")

if is_binary(github_webhook_secret) and github_webhook_secret != "" do
  config :glossia, Glossia.Github, webhook_secret: github_webhook_secret
end

if is_binary(gitlab_webhook_secret) and gitlab_webhook_secret != "" do
  config :glossia, Glossia.Gitlab, webhook_secret: gitlab_webhook_secret
end

minimax_api_key = System.get_env("MINIMAX_API_KEY")

if is_binary(minimax_api_key) and minimax_api_key != "" do
  config :glossia, Glossia.Minimax, api_key: minimax_api_key
end

s3_access_key = System.get_env("S3_ACCESS_KEY_ID")
s3_secret_key = System.get_env("S3_SECRET_ACCESS_KEY")
s3_endpoint = System.get_env("S3_ENDPOINT")
s3_region = System.get_env("S3_REGION", "auto")
s3_bucket = System.get_env("S3_BUCKET", "glossia")

if is_binary(s3_access_key) and s3_access_key != "" do
  config :ex_aws,
    access_key_id: s3_access_key,
    secret_access_key: s3_secret_key,
    region: s3_region

  s3_host = URI.parse(s3_endpoint).host
  config :ex_aws, :s3, scheme: "https://", host: s3_host, port: 443

  config :glossia, Glossia.Storage, bucket: s3_bucket
end

oauth_providers =
  []
  |> then(fn providers ->
    case {System.get_env("GITHUB_CLIENT_ID"), System.get_env("GITHUB_CLIENT_SECRET")} do
      {id, secret} when is_binary(id) and is_binary(secret) ->
        Keyword.put(providers, :github,
          client_id: id,
          client_secret: secret,
          strategy: Assent.Strategy.Github
        )

      _ ->
        providers
    end
  end)
  |> then(fn providers ->
    case {System.get_env("GITLAB_CLIENT_ID"), System.get_env("GITLAB_CLIENT_SECRET")} do
      {id, secret} when is_binary(id) and is_binary(secret) ->
        Keyword.put(providers, :gitlab,
          client_id: id,
          client_secret: secret,
          strategy: Assent.Strategy.Gitlab,
          authorization_params: [scope: "openid email profile"]
        )

      _ ->
        providers
    end
  end)

config :glossia, :oauth_providers, oauth_providers

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  otel_protocol =
    case System.get_env("OTEL_EXPORTER_OTLP_PROTOCOL", "grpc") do
      "grpc" -> :grpc
      "http_protobuf" -> :http_protobuf
      protocol -> raise "unsupported OTEL_EXPORTER_OTLP_PROTOCOL=#{inspect(protocol)}"
    end

  metrics_bearer_token =
    System.get_env("METRICS_BEARER_TOKEN") ||
      raise """
      environment variable METRICS_BEARER_TOKEN is missing.
      Generate one with: mix phx.gen.secret 32
      """

  config :glossia, GlossiaWeb.Plugs.Metrics, bearer_token: metrics_bearer_token

  ops_auth_password = System.get_env("OPS_AUTH_PASSWORD")

  if is_nil(ops_auth_password) or ops_auth_password == "" do
    raise "environment variable OPS_AUTH_PASSWORD is missing or empty."
  end

  config :glossia, GlossiaWeb.Plugs.OpsAuth,
    username: "ops",
    password: ops_auth_password

  otel_service_name = System.get_env("OTEL_SERVICE_NAME", "glossia-web")
  otel_deployment_environment = System.get_env("OTEL_DEPLOYMENT_ENVIRONMENT", "production")
  loki_url = System.get_env("LOKI_URL", "http://glossia-loki:3100")
  loki_org_id = System.get_env("LOKI_ORG_ID", "fake")
  sentry_dsn = System.get_env("SENTRY_DSN")
  sentry_dsn_js = System.get_env("SENTRY_DSN_JS")

  if is_binary(sentry_dsn) and sentry_dsn != "" do
    config :sentry,
      dsn: sentry_dsn,
      environment_name: otel_deployment_environment,
      release: to_string(Application.spec(:glossia, :vsn))

    config :glossia, :logger, [
      {:handler, :glossia_sentry, Sentry.LoggerHandler,
       %{
         config: %{
           metadata: [:file, :line],
           rate_limiting: [max_events: 10, interval: 1_000],
           capture_log_messages: true,
           level: :error
         }
       }}
    ]
  end

  if is_binary(sentry_dsn_js) and sentry_dsn_js != "" do
    config :glossia, :sentry_dsn_js, sentry_dsn_js
  end

  config :glossia, Glossia.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  clickhouse_url =
    System.get_env("CLICKHOUSE_URL") ||
      raise """
      environment variable CLICKHOUSE_URL is missing.
      For example: http://localhost:8123/glossia
      """

  clickhouse_pool_size = String.to_integer(System.get_env("CLICKHOUSE_POOL_SIZE") || "5")

  config :glossia, Glossia.ClickHouseRepo,
    url: clickhouse_url,
    pool_size: clickhouse_pool_size,
    queue_target: 5000,
    queue_interval: 1000,
    settings: [
      readonly: 1,
      join_algorithm: "direct,parallel_hash,hash"
    ],
    transport_opts: [
      keepalive: true,
      show_econnreset: true,
      inet6: System.get_env("ECTO_IPV6") in ~w(true 1)
    ]

  config :glossia, Glossia.IngestRepo,
    url: clickhouse_url,
    pool_size: clickhouse_pool_size,
    queue_target: 5000,
    queue_interval: 1000,
    flush_interval_ms:
      String.to_integer(System.get_env("CLICKHOUSE_FLUSH_INTERVAL_MS") || "5000"),
    max_buffer_size: String.to_integer(System.get_env("CLICKHOUSE_MAX_BUFFER_SIZE") || "100000"),
    transport_opts: [
      keepalive: true,
      show_econnreset: true,
      inet6: System.get_env("ECTO_IPV6") in ~w(true 1)
    ]

  config :opentelemetry,
    span_processor: :batch,
    traces_exporter: :otlp,
    resource: [
      service: %{
        name: otel_service_name,
        version: to_string(Application.spec(:glossia, :vsn))
      },
      deployment: %{
        environment: otel_deployment_environment
      }
    ]

  config :opentelemetry_exporter,
    otlp_protocol: otel_protocol,
    otlp_endpoint: System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT", "http://glossia-alloy:4317")

  config :logger, :backends, [:console, Glossia.Logger.LokiBackend]

  config :logger, Glossia.Logger.LokiBackend,
    level: :info,
    metadata: [:request_id, :trace_id, :span_id],
    max_buffer: 20,
    flush_interval_ms: 1_000,
    url: loki_url,
    org_id: loki_org_id,
    labels: %{
      service: otel_service_name,
      environment: otel_deployment_environment,
      source: "elixir-runtime"
    }

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

  config :glossia, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :boruta, Boruta.Oauth, issuer: "https://#{host}"

  config :glossia, GlossiaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
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
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :glossia, GlossiaWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  smtp_host = System.get_env("SMTP_HOST") || "smtp.useplunk.com"
  smtp_port = String.to_integer(System.get_env("SMTP_PORT") || "587")
  smtp_username = System.get_env("SMTP_USERNAME") || "plunk"

  smtp_password =
    System.get_env("SMTP_PASSWORD") ||
      raise """
      environment variable SMTP_PASSWORD is missing.
      """

  config :glossia, Glossia.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: smtp_host,
    port: smtp_port,
    username: smtp_username,
    password: smtp_password,
    tls: :always,
    ssl: false,
    auth: :always,
    no_mx_lookups: true,
    tls_options: [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      depth: 3,
      server_name_indication: String.to_charlist(smtp_host)
    ]
end
