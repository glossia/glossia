import Config

truthy? = fn value -> value in ["true", "1"] end

# The compiled edition selects the runtime, not a release-time edition env var.
translation_runtime = Glossia.Extensions.translation_runtime()
runner_child? = translation_runtime.runner_child?()
translation_job? = translation_runtime.translation_job?()

json_env = fn name, default ->
  case System.get_env(name) do
    nil -> default
    "" -> default
    value -> JSON.decode!(value)
  end
end

integer_env = fn name, default ->
  case System.get_env(name) do
    nil -> default
    "" -> default
    value -> String.to_integer(value)
  end
end

float_env = fn name, default ->
  case System.get_env(name) do
    nil ->
      default

    "" ->
      default

    value ->
      case Float.parse(value) do
        {parsed, ""} -> parsed
        _ -> raise "unsupported #{name}=#{inspect(value)}, expected a float"
      end
  end
end

# The engine release is independent of the repository commit being translated.
config :glossia,
  engine_image: System.get_env("GLOSSIA_ENGINE_IMAGE"),
  engine_deployment: System.get_env("GLOSSIA_ENGINE_DEPLOYMENT")

# Detached translation Job settings. Each translation session runs in its
# own Job pod scheduled by the enterprise translation runtime.
config :glossia, :translation_job,
  ttl_seconds_after_finished:
    integer_env.("GLOSSIA_TRANSLATION_JOB_TTL_SECONDS_AFTER_FINISHED", 3_600),
  active_deadline_seconds:
    integer_env.("GLOSSIA_TRANSLATION_JOB_ACTIVE_DEADLINE_SECONDS", 86_400),
  resources: json_env.("GLOSSIA_TRANSLATION_JOB_RESOURCES_JSON", %{})

# Managed runner pool. Every setting has an env-var override so the operator
# can tune it without rebuilding the image.
config :glossia, :managed_runner,
  min: integer_env.("GLOSSIA_MANAGED_MIN", 2),
  max: integer_env.("GLOSSIA_MANAGED_MAX", 20),
  max_concurrency: integer_env.("GLOSSIA_MANAGED_MAX_CONCURRENCY", 2),
  idle_shutdown_after: integer_env.("GLOSSIA_MANAGED_IDLE_SHUTDOWN_MS", 300_000),
  timeout: integer_env.("GLOSSIA_MANAGED_TIMEOUT_MS", 3_600_000),
  boot_timeout: integer_env.("GLOSSIA_MANAGED_BOOT_TIMEOUT_MS", 180_000),
  log: truthy?.(System.get_env("GLOSSIA_MANAGED_LOG")),
  k8s: [
    app_container_name: System.get_env("GLOSSIA_MANAGED_APP_CONTAINER_NAME") || "web",
    runtime_class_name: System.get_env("GLOSSIA_MANAGED_RUNTIME_CLASS_NAME"),
    resources: json_env.("GLOSSIA_MANAGED_RESOURCES_JSON", %{}),
    node_selector:
      json_env.("GLOSSIA_MANAGED_NODE_SELECTOR_JSON", %{
        "glossia.io/managed-runner" => "true"
      }),
    tolerations: json_env.("GLOSSIA_MANAGED_TOLERATIONS_JSON", []),
    affinity: json_env.("GLOSSIA_MANAGED_AFFINITY_JSON", %{}),
    env: json_env.("GLOSSIA_MANAGED_ENV_JSON", %{}),
    log: truthy?.(System.get_env("GLOSSIA_MANAGED_K8S_LOG"))
  ]

# How many HTTP connections the node holds open per host. Translation is the
# heaviest user: every concurrent file is one long-lived connection to the model
# gateway, and asking for more concurrent translations than this only parks the
# extras in Finch's checkout queue until they time out.
config :glossia, :http_pool_size, integer_env.("GLOSSIA_HTTP_POOL_SIZE", 50)

config :glossia, Glossia.Push, Glossia.Push.Config.parse!(System.get_env())

# Cloudflare Turnstile enforcement for the sign-up surface. Single
# per-environment toggle; site + secret keys are projected from the
# operator-materialized Secret in the workload cluster.
config :glossia, Glossia.Cloudflare.Turnstile,
  enabled?: truthy?.(System.get_env("GLOSSIA_TURNSTILE_ENABLED", "0")),
  site_key: System.get_env("GLOSSIA_TURNSTILE_SITE_KEY"),
  secret_key: System.get_env("GLOSSIA_TURNSTILE_SECRET_KEY")

# Cloudflare Turnstile enforcement for the public-page browse
# interstitial. A separate widget from the signup one so telemetry,
# rotation, and blast radius stay isolated. The FunWithFlags flag
# `:public_page_challenge_kill_switch` can pull enforcement at runtime
# without a deploy. Freshness is how long a solved challenge lets a
# visitor browse without re-solving.
config :glossia, Glossia.Cloudflare.Turnstile.PublicPage,
  enabled?: truthy?.(System.get_env("GLOSSIA_PUBLIC_PAGE_CHALLENGE_ENABLED", "0")),
  site_key: System.get_env("GLOSSIA_PUBLIC_PAGE_CHALLENGE_SITE_KEY"),
  secret_key: System.get_env("GLOSSIA_PUBLIC_PAGE_CHALLENGE_SECRET_KEY"),
  freshness_seconds: integer_env.("GLOSSIA_PUBLIC_PAGE_CHALLENGE_FRESHNESS_SECONDS", 3_600)

# Translation LLM credential. Precedence at resolve time: the account's own model
# key, then this globally configured inference provider (token + URL), then — in
# dev only — the local Claude/Codex session.
config :glossia, Glossia.Translations,
  inference_model: System.get_env("GLOSSIA_TRANSLATION_MODEL"),
  inference_api_key: System.get_env("GLOSSIA_TRANSLATION_API_KEY"),
  inference_base_url: System.get_env("GLOSSIA_TRANSLATION_BASE_URL"),
  local_session_model: System.get_env("GLOSSIA_TRANSLATION_LOCAL_MODEL"),
  allow_local_session:
    System.get_env("GLOSSIA_TRANSLATION_ALLOW_LOCAL_SESSION", to_string(config_env() == :dev)) not in [
      "false",
      "0"
    ]

# Toki never borrows a local session implicitly. Only an explicit development
# server opt-in selects the tool-less host adapter; production ignores the env.
config :glossia,
       Glossia.Toki.HostHarness,
       Glossia.Toki.HostHarness.config(config_env(), System.get_env())

smolanalytics_url = System.get_env("GLOSSIA_SMOLANALYTICS_URL")
smolanalytics_write_key = System.get_env("GLOSSIA_SMOLANALYTICS_WRITE_KEY")

smolanalytics_enabled =
  case {smolanalytics_url, smolanalytics_write_key, runner_child?} do
    {_, _, true} ->
      false

    {url, key, false}
    when is_binary(url) and url != "" and is_binary(key) and key != "" ->
      true

    {url, key, false} when url in [nil, ""] and key in [nil, ""] ->
      false

    _ ->
      raise """
      GLOSSIA_SMOLANALYTICS_URL and GLOSSIA_SMOLANALYTICS_WRITE_KEY must either both be set or both be omitted.
      """
  end

config :glossia, Glossia.Analytics.Smolanalytics,
  enabled: smolanalytics_enabled,
  url: smolanalytics_url,
  write_key: smolanalytics_write_key,
  environment: System.get_env("OTEL_DEPLOYMENT_ENVIRONMENT") || Atom.to_string(config_env())

typesense_url = System.get_env("GLOSSIA_TYPESENSE_URL")
typesense_api_key = System.get_env("GLOSSIA_TYPESENSE_API_KEY")

config :glossia, Glossia.Docs.Search,
  enabled:
    not runner_child? and not translation_job? and is_binary(typesense_url) and
      typesense_url != "" and
      is_binary(typesense_api_key) and typesense_api_key != "",
  url: typesense_url,
  api_key: typesense_api_key

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing GLOSSIA_PHX_SERVER=true or PHX_SERVER=true when you start it:
#
#     GLOSSIA_PHX_SERVER=true bin/glossia start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
# Truthiness, not presence: "false" is a truthy string in Elixir, so a pod that
# explicitly turns the server off - a translation job does - would otherwise
# still be configured to serve.
phx_server? =
  truthy?.(System.get_env("GLOSSIA_PHX_SERVER") || System.get_env("PHX_SERVER") || "false")

if not runner_child? and not translation_job? and phx_server? do
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
github_api_url = System.get_env("GLOSSIA_GITHUB_API_URL")
github_app_url = System.get_env("GLOSSIA_GITHUB_APP_URL")

if is_binary(github_app_id) and github_app_id != "" do
  config :glossia, Glossia.Github.App,
    app_id: github_app_id,
    private_key: github_app_private_key,
    app_slug: github_app_slug,
    api_url: github_api_url,
    app_url: github_app_url
end

if is_binary(github_api_url) and github_api_url != "" do
  config :glossia, Glossia.Github.Client, api_url: github_api_url
end

if is_binary(gitlab_webhook_secret) and gitlab_webhook_secret != "" do
  config :glossia, Glossia.Gitlab, webhook_secret: gitlab_webhook_secret
end

s3_access_key = System.get_env("GLOSSIA_S3_ACCESS_KEY_ID")
s3_secret_key = System.get_env("GLOSSIA_S3_SECRET_ACCESS_KEY")
s3_endpoint = System.get_env("GLOSSIA_S3_ENDPOINT")
s3_region = System.get_env("GLOSSIA_S3_REGION", "auto")
s3_bucket = System.get_env("GLOSSIA_S3_BUCKET", "glossia")

if System.get_env("GLOSSIA_OG_IMAGES") in ["true", "false"] do
  config :glossia, Glossia.OgImage, enabled: System.get_env("GLOSSIA_OG_IMAGES") == "true"
end

if is_binary(s3_access_key) and s3_access_key != "" do
  config :ex_aws,
    access_key_id: s3_access_key,
    secret_access_key: s3_secret_key,
    region: s3_region

  if is_binary(s3_endpoint) and s3_endpoint != "" do
    s3_uri =
      if String.contains?(s3_endpoint, "://") do
        URI.parse(s3_endpoint)
      else
        URI.parse("https://#{s3_endpoint}")
      end

    s3_scheme = "#{s3_uri.scheme}://"
    s3_port = s3_uri.port || if(s3_scheme == "http://", do: 80, else: 443)

    config :ex_aws, :s3,
      scheme: s3_scheme,
      host: s3_uri.host || s3_endpoint,
      port: s3_port
  end

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

oauth_providers =
  case {System.get_env("GLOSSIA_GOOGLE_CLIENT_ID"),
        System.get_env("GLOSSIA_GOOGLE_CLIENT_SECRET")} do
    {id, secret} when is_binary(id) and id != "" and is_binary(secret) and secret != "" ->
      Keyword.put(oauth_providers, :google,
        client_id: id,
        client_secret: secret,
        strategy: Assent.Strategy.Google,
        nonce: true
      )

    _ ->
      oauth_providers
  end

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

if config_env() == :prod and not runner_child? do
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
      "http/protobuf" -> :http_protobuf
      "http_protobuf" -> :http_protobuf
      protocol -> raise "unsupported OTEL_EXPORTER_OTLP_PROTOCOL=#{inspect(protocol)}"
    end

  otel_exporter_endpoint = System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT")
  enable_otel_exporter = is_binary(otel_exporter_endpoint) and otel_exporter_endpoint != ""

  if not runner_child? do
    metrics_bearer_token =
      System.get_env("GLOSSIA_METRICS_BEARER_TOKEN") ||
        raise """
        environment variable GLOSSIA_METRICS_BEARER_TOKEN is missing.
        Generate one with: mix phx.gen.secret 32
        """

    config :glossia, GlossiaWeb.Plugs.Metrics, bearer_token: metrics_bearer_token
  end

  default_otel_service_name =
    cond do
      runner_child? -> "glossia-runner"
      translation_job? -> "glossia-translation"
      true -> "glossia-web"
    end

  otel_service_name = System.get_env("OTEL_SERVICE_NAME", default_otel_service_name)
  otel_deployment_environment = System.get_env("OTEL_DEPLOYMENT_ENVIRONMENT", "production")
  loki_url = System.get_env("GLOSSIA_LOKI_URL")
  enable_loki_logging = is_binary(loki_url) and loki_url != ""
  loki_org_id = System.get_env("GLOSSIA_LOKI_ORG_ID", "fake")
  sentry_dsn = System.get_env("GLOSSIA_SENTRY_DSN")
  sentry_dsn_js = System.get_env("GLOSSIA_SENTRY_DSN_JS")

  if is_binary(sentry_dsn) and sentry_dsn != "" do
    config :sentry,
      dsn: sentry_dsn,
      environment_name: otel_deployment_environment,
      release: to_string(Application.spec(:glossia, :vsn)),
      oban: [
        capture_errors: true,
        should_report_error_callback: &Glossia.SentryOban.report_error?/2
      ]

    config :glossia, :logger, [
      {:handler, :glossia_sentry, Sentry.LoggerHandler,
       %{
         config: %{
           metadata: [:file, :line],
           rate_limiting: [max_events: 10, interval: 1_000]
         }
       }}
    ]
  end

  if is_binary(sentry_dsn_js) and sentry_dsn_js != "" do
    config :glossia, :sentry_dsn_js, sentry_dsn_js
  end

  repo_pool_size = String.to_integer(System.get_env("GLOSSIA_POOL_SIZE") || "10")

  config :glossia, Glossia.Repo,
    url: database_url,
    pool_size: repo_pool_size,
    socket_options: maybe_ipv6

  clickhouse_url =
    System.get_env("GLOSSIA_CLICKHOUSE_URL") ||
      raise """
      environment variable GLOSSIA_CLICKHOUSE_URL is missing.
      For example: http://localhost:8123/glossia
      """

  # Production routes read workloads through a distinct ClickHouse account.
  # Local development and tests keep using the standard local URL.
  clickhouse_readonly_url = System.get_env("GLOSSIA_CLICKHOUSE_READONLY_URL") || clickhouse_url

  clickhouse_pool_size = String.to_integer(System.get_env("GLOSSIA_CLICKHOUSE_POOL_SIZE") || "5")

  config :glossia, Glossia.ClickHouseRepo,
    url: clickhouse_readonly_url,
    pool_size: clickhouse_pool_size,
    queue_target: 5000,
    queue_interval: 1000,
    settings: [
      readonly: 1,
      join_algorithm: "direct,parallel_hash,hash",
      # The ClickHouse client uses RowBinary result encoding and needs these
      # format settings to decode document values. The server profile pins them.
      input_format_binary_read_json_as_string: 1,
      output_format_binary_write_json_as_string: 1
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
    resource: [
      service: %{
        name: otel_service_name,
        version: to_string(Application.spec(:glossia, :vsn))
      },
      deployment: %{
        environment: otel_deployment_environment
      }
    ]

  if enable_otel_exporter do
    config :opentelemetry, traces_exporter: :otlp

    config :opentelemetry_exporter,
      otlp_protocol: otel_protocol,
      otlp_endpoint: otel_exporter_endpoint
  end

  if enable_loki_logging do
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
  else
    config :logger, :backends, [:console]
  end

  secret_key_base =
    System.get_env("GLOSSIA_SECRET_KEY_BASE") ||
      raise """
      environment variable GLOSSIA_SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("GLOSSIA_HOST") || "example.com"

  pomerium_access_host = System.get_env("GLOSSIA_POMERIUM_ACCESS_HOST") || "access.glossia.ai"

  config :glossia, Glossia.Pomerium,
    enabled: true,
    email_domain: "glossia.ai",
    expected_issuer: pomerium_access_host,
    expected_audience: pomerium_access_host,
    jwks_url: "https://#{pomerium_access_host}/.well-known/pomerium/jwks.json"

  babel_internal_endpoint =
    case System.get_env("GLOSSIA_BABEL_INTERNAL_TLS_CERT_PATH") do
      nil ->
        [server: false]

      certfile ->
        keyfile = System.fetch_env!("GLOSSIA_BABEL_INTERNAL_TLS_KEY_PATH")

        [
          server: true,
          https: [
            ip: {0, 0, 0, 0, 0, 0, 0, 0},
            port: 4051,
            cipher_suite: :strong,
            certfile: certfile,
            keyfile: keyfile
          ]
        ]
    end

  config :glossia, :dns_cluster_query, System.get_env("GLOSSIA_DNS_CLUSTER_QUERY")

  config :boruta, Boruta.Oauth, issuer: "https://#{host}"

  config :glossia,
         GlossiaWeb.BabelInternalEndpoint,
         [secret_key_base: secret_key_base] ++ babel_internal_endpoint

  config :glossia,
         GlossiaWeb.Endpoint,
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

  smtp_tls =
    case String.downcase(System.get_env("GLOSSIA_SMTP_TLS") || "always") do
      "always" -> :always
      "if_available" -> :if_available
      "never" -> :never
      value -> raise "unsupported GLOSSIA_SMTP_TLS=#{inspect(value)}"
    end

  smtp_auth =
    case String.downcase(System.get_env("GLOSSIA_SMTP_AUTH") || "always") do
      "always" -> :always
      "never" -> :never
      value -> raise "unsupported GLOSSIA_SMTP_AUTH=#{inspect(value)}"
    end

  smtp_auth_options =
    case smtp_auth do
      :always ->
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

        [
          username: smtp_username,
          password: smtp_password,
          auth: :always
        ]

      :never ->
        [auth: :never]
    end

  smtp_tls_options =
    case smtp_tls do
      :never ->
        []

      _ ->
        [
          tls_options: [
            verify: :verify_peer,
            cacerts: :public_key.cacerts_get(),
            depth: 3,
            server_name_indication: String.to_charlist(smtp_host)
          ]
        ]
    end

  smtp_options =
    [
      adapter: Swoosh.Adapters.SMTP,
      relay: smtp_host,
      port: smtp_port,
      tls: smtp_tls,
      ssl: false,
      no_mx_lookups: true
    ] ++ smtp_auth_options ++ smtp_tls_options

  config :glossia, Glossia.Mailer, smtp_options

  analytics_secret =
    System.get_env("GLOSSIA_ANALYTICS_IDENTITY_SECRET") ||
      if System.get_env("GLOSSIA_MIGRATION") == "true" do
        "migration-only"
      else
        raise """
        environment variable GLOSSIA_ANALYTICS_IDENTITY_SECRET is missing.
        This secret salts the daily-rotated visitor hash; it must be stable and
        secret. Generate one with: mix phx.gen.secret
        """
      end

  geoip_database_path = System.get_env("GLOSSIA_GEOIP_DATABASE_PATH")

  geo_adapter =
    if geoip_database_path,
      do: Glossia.Analytics.Geolocation.Maxmind,
      else: Glossia.Analytics.Geolocation.Ipapi

  config :glossia, GlossiaWeb.ClientIP,
    trust_cloudflare_header:
      System.get_env("GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER") in ~w(true 1)

  config :glossia, Glossia.Analytics,
    enabled: System.get_env("GLOSSIA_ANALYTICS_ENABLED") not in ~w(false 0),
    identity_secret: analytics_secret,
    # Enable only after authenticating Cloudflare at the origin or sanitizing
    # inbound headers. The public origin must not accept forged CF-IPCountry.
    trust_cloudflare_country_header:
      System.get_env("GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER") in ~w(true 1),
    geolocation: [adapter: geo_adapter, database_path: geoip_database_path]

  config :glossia, :web_analytics, domain: System.get_env("GLOSSIA_WEB_ANALYTICS_DOMAIN")

  # Load the UAInspector regex database from the release's writable priv dir.
  config :ua_inspector, init: {Glossia.Release, :configure_ua_inspector}
end
