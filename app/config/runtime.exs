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
# by passing the GLOSSIA_PHX_SERVER=true when you start it:
#
#     GLOSSIA_PHX_SERVER=true bin/glossia start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("GLOSSIA_PHX_SERVER") do
  config :glossia, GlossiaWeb.Endpoint, server: true
end

config :glossia, GlossiaWeb.Endpoint,
  http: [
    port:
      String.to_integer(System.get_env("PORT") || System.get_env("GLOSSIA_SERVER_PORT") || "4050")
  ]

if config_env() == :dev do
  if postgres_db = System.get_env("GLOSSIA_POSTGRES_DB") do
    config :glossia, Glossia.Repo, database: postgres_db
  end

  if clickhouse_db = System.get_env("GLOSSIA_CLICKHOUSE_DB") do
    config :glossia, Glossia.ClickHouseRepo, database: clickhouse_db
    config :glossia, Glossia.IngestRepo, database: clickhouse_db
  end

  if server_url = System.get_env("GLOSSIA_SERVER_URL") do
    config :boruta, Boruta.Oauth, issuer: server_url
  end
end

if config_env() == :test do
  if postgres_db = System.get_env("GLOSSIA_TEST_POSTGRES_DB") do
    config :glossia, Glossia.Repo, database: postgres_db
  end

  if clickhouse_db = System.get_env("GLOSSIA_TEST_CLICKHOUSE_DB") do
    config :glossia, Glossia.ClickHouseRepo, database: clickhouse_db
    config :glossia, Glossia.IngestRepo, database: clickhouse_db
  end

  if test_port = System.get_env("GLOSSIA_TEST_PORT") do
    config :glossia, GlossiaWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: String.to_integer(test_port)]
  end
end

github_webhook_secret = System.get_env("GLOSSIA_GITHUB_WEBHOOK_SECRET")
gitlab_webhook_secret = System.get_env("GLOSSIA_GITLAB_WEBHOOK_SECRET")

if is_binary(github_webhook_secret) and github_webhook_secret != "" do
  config :glossia, Glossia.Github, webhook_secret: github_webhook_secret
end

github_app_id = System.get_env("GLOSSIA_GITHUB_APP_ID")
github_app_private_key = System.get_env("GLOSSIA_GITHUB_APP_PRIVATE_KEY")
github_app_slug = System.get_env("GLOSSIA_GITHUB_APP_SLUG")

if is_binary(github_app_id) and github_app_id != "" do
  config :glossia, Glossia.Github.App,
    app_id: github_app_id,
    private_key: github_app_private_key,
    app_slug: github_app_slug
end

if is_binary(gitlab_webhook_secret) and gitlab_webhook_secret != "" do
  config :glossia, Glossia.Gitlab, webhook_secret: gitlab_webhook_secret
end

s3_access_key = System.get_env("GLOSSIA_S3_ACCESS_KEY_ID")
s3_secret_key = System.get_env("GLOSSIA_S3_SECRET_ACCESS_KEY")
s3_endpoint = System.get_env("GLOSSIA_S3_ENDPOINT")
s3_region = System.get_env("GLOSSIA_S3_REGION", "auto")
s3_bucket = System.get_env("GLOSSIA_S3_BUCKET", "glossia")

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
    case {System.get_env("GLOSSIA_GITHUB_CLIENT_ID"),
          System.get_env("GLOSSIA_GITHUB_CLIENT_SECRET")} do
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
    case {System.get_env("GLOSSIA_GITLAB_CLIENT_ID"),
          System.get_env("GLOSSIA_GITLAB_CLIENT_SECRET")} do
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

encryption_key = System.get_env("GLOSSIA_ENCRYPTION_KEY")

if is_binary(encryption_key) and encryption_key != "" do
  config :glossia, Glossia.Vault,
    ciphers: [
      default: {
        Cloak.Ciphers.AES.GCM,
        tag: "AES.GCM.V1", key: Base.decode64!(encryption_key), iv_length: 12
      }
    ]
end

if config_env() == :prod do
  database_url =
    System.get_env("GLOSSIA_DATABASE_URL") ||
      raise """
      environment variable GLOSSIA_DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("GLOSSIA_ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  otel_protocol =
    case System.get_env("OTEL_EXPORTER_OTLP_PROTOCOL", "grpc") do
      "grpc" -> :grpc
      "http_protobuf" -> :http_protobuf
      protocol -> raise "unsupported OTEL_EXPORTER_OTLP_PROTOCOL=#{inspect(protocol)}"
    end

  metrics_bearer_token =
    System.get_env("GLOSSIA_METRICS_BEARER_TOKEN") ||
      raise """
      environment variable GLOSSIA_METRICS_BEARER_TOKEN is missing.
      Generate one with: mix phx.gen.secret 32
      """

  config :glossia, GlossiaWeb.Plugs.Metrics, bearer_token: metrics_bearer_token

  ops_auth_password = System.get_env("GLOSSIA_OPS_AUTH_PASSWORD")

  if is_nil(ops_auth_password) or ops_auth_password == "" do
    raise "environment variable GLOSSIA_OPS_AUTH_PASSWORD is missing or empty."
  end

  config :glossia, GlossiaWeb.Plugs.OpsAuth,
    username: "ops",
    password: ops_auth_password

  otel_service_name = System.get_env("OTEL_SERVICE_NAME", "glossia-web")
  otel_deployment_environment = System.get_env("OTEL_DEPLOYMENT_ENVIRONMENT", "production")
  loki_url = System.get_env("GLOSSIA_LOKI_URL", "http://glossia-loki:3100")
  loki_org_id = System.get_env("GLOSSIA_LOKI_ORG_ID", "fake")
  sentry_dsn = System.get_env("GLOSSIA_SENTRY_DSN")
  sentry_dsn_js = System.get_env("GLOSSIA_SENTRY_DSN_JS")

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
    url: database_url,
    pool_size: String.to_integer(System.get_env("GLOSSIA_POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  clickhouse_url =
    System.get_env("GLOSSIA_CLICKHOUSE_URL") ||
      raise """
      environment variable GLOSSIA_CLICKHOUSE_URL is missing.
      For example: http://localhost:8123/glossia
      """

  clickhouse_pool_size =
    String.to_integer(System.get_env("GLOSSIA_CLICKHOUSE_POOL_SIZE") || "5")

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
      inet6: System.get_env("GLOSSIA_ECTO_IPV6") in ~w(true 1)
    ]

  config :glossia, Glossia.IngestRepo,
    url: clickhouse_url,
    pool_size: clickhouse_pool_size,
    queue_target: 5000,
    queue_interval: 1000,
    flush_interval_ms:
      String.to_integer(System.get_env("GLOSSIA_CLICKHOUSE_FLUSH_INTERVAL_MS") || "5000"),
    max_buffer_size:
      String.to_integer(System.get_env("GLOSSIA_CLICKHOUSE_MAX_BUFFER_SIZE") || "100000"),
    transport_opts: [
      keepalive: true,
      show_econnreset: true,
      inet6: System.get_env("GLOSSIA_ECTO_IPV6") in ~w(true 1)
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

  secret_key_base =
    System.get_env("GLOSSIA_SECRET_KEY_BASE") ||
      raise """
      environment variable GLOSSIA_SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("GLOSSIA_HOST") || "example.com"

  config :glossia, :dns_cluster_query, System.get_env("GLOSSIA_DNS_CLUSTER_QUERY")

  config :boruta, Boruta.Oauth, issuer: "https://#{host}"

  config :glossia, GlossiaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  smtp_host =
    System.get_env("GLOSSIA_SMTP_HOST") ||
      raise """
      environment variable GLOSSIA_SMTP_HOST is missing.
      """

  smtp_port = String.to_integer(System.get_env("GLOSSIA_SMTP_PORT") || "587")

  smtp_username =
    System.get_env("GLOSSIA_SMTP_USERNAME") ||
      raise """
      environment variable GLOSSIA_SMTP_USERNAME is missing.
      """

  smtp_password =
    System.get_env("GLOSSIA_SMTP_PASSWORD") ||
      raise """
      environment variable GLOSSIA_SMTP_PASSWORD is missing.
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
