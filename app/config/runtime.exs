import Config

truthy? = fn value -> value in ["true", "1"] end

flame_child? = not is_nil(FLAME.Parent.get())
isolated_child? = truthy?.(System.get_env("GLOSSIA_ISOLATED_CHILD"))
runner_child? = flame_child? or isolated_child?

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

default_flame_backend =
  cond do
    config_env() == :test -> :local
    System.get_env("KUBERNETES_SERVICE_HOST") -> :k8s
    true -> :local
  end

flame_backend =
  case System.get_env("GLOSSIA_FLAME_BACKEND") do
    nil ->
      default_flame_backend

    "" ->
      default_flame_backend

    "local" ->
      :local

    "k8s" ->
      :k8s

    value ->
      raise "unsupported GLOSSIA_FLAME_BACKEND=#{inspect(value)}"
  end

config :glossia, :flame,
  backend: flame_backend,
  min: String.to_integer(System.get_env("GLOSSIA_FLAME_MIN") || "0"),
  max: String.to_integer(System.get_env("GLOSSIA_FLAME_MAX") || "10"),
  max_concurrency: String.to_integer(System.get_env("GLOSSIA_FLAME_MAX_CONCURRENCY") || "1"),
  idle_shutdown_after:
    String.to_integer(System.get_env("GLOSSIA_FLAME_IDLE_SHUTDOWN_AFTER_MS") || "30000"),
  timeout: String.to_integer(System.get_env("GLOSSIA_FLAME_TIMEOUT_MS") || "300000"),
  boot_timeout: String.to_integer(System.get_env("GLOSSIA_FLAME_BOOT_TIMEOUT_MS") || "120000"),
  log: truthy?.(System.get_env("GLOSSIA_FLAME_LOG")),
  k8s: [
    app_container_name: System.get_env("GLOSSIA_FLAME_APP_CONTAINER_NAME") || "web",
    runtime_class_name: System.get_env("GLOSSIA_FLAME_RUNTIME_CLASS_NAME"),
    resources: json_env.("GLOSSIA_FLAME_RESOURCES_JSON", %{}),
    node_selector: json_env.("GLOSSIA_FLAME_NODE_SELECTOR_JSON", %{}),
    tolerations: json_env.("GLOSSIA_FLAME_TOLERATIONS_JSON", []),
    affinity: json_env.("GLOSSIA_FLAME_AFFINITY_JSON", %{}),
    env: json_env.("GLOSSIA_FLAME_ENV_JSON", %{}),
    log: truthy?.(System.get_env("GLOSSIA_FLAME_K8S_LOG"))
  ]

sandbox_adapter =
  case System.get_env("GLOSSIA_SANDBOX_ADAPTER") ||
         if(config_env() == :dev, do: "microsandbox", else: "cluster") do
    "cluster" -> Glossia.Sandbox.ClusterAdapter
    "microsandbox" -> Glossia.Sandbox.MicrosandboxAdapter
    value -> raise "unsupported GLOSSIA_SANDBOX_ADAPTER=#{inspect(value)}"
  end

microsandbox_image_default =
  case {config_env(), System.get_env("GLOSSIA_DEV_INSTANCE")} do
    {:dev, instance} when is_binary(instance) and instance != "" -> "glossia-local:#{instance}"
    _ -> "glossia-local:dev"
  end

config :glossia, Glossia.Sandbox,
  adapter: sandbox_adapter,
  enabled: System.get_env("GLOSSIA_SANDBOX_ENABLED", "true") not in ["false", "0"],
  max_active_per_account:
    String.to_integer(System.get_env("GLOSSIA_SANDBOX_MAX_ACTIVE_PER_ACCOUNT") || "3"),
  default_ttl_seconds:
    String.to_integer(System.get_env("GLOSSIA_SANDBOX_DEFAULT_TTL_SECONDS") || "3600"),
  command_timeout_ms:
    String.to_integer(System.get_env("GLOSSIA_SANDBOX_COMMAND_TIMEOUT_MS") || "120000"),
  output_limit_bytes:
    String.to_integer(System.get_env("GLOSSIA_SANDBOX_OUTPUT_LIMIT_BYTES") || "256000"),
  file_transfer_limit_bytes:
    String.to_integer(System.get_env("GLOSSIA_SANDBOX_FILE_TRANSFER_LIMIT_BYTES") || "16777216"),
  reaper_enabled:
    System.get_env(
      "GLOSSIA_SANDBOX_REAPER_ENABLED",
      if(config_env() == :test, do: "false", else: "true")
    ) not in ["false", "0"],
  reaper_interval_ms:
    String.to_integer(System.get_env("GLOSSIA_SANDBOX_REAPER_INTERVAL_MS") || "60000"),
  delete_retry_after_ms:
    String.to_integer(System.get_env("GLOSSIA_SANDBOX_DELETE_RETRY_AFTER_MS") || "60000"),
  microsandbox_command: System.get_env("GLOSSIA_MICROSANDBOX_COMMAND") || "msb",
  microsandbox_image: System.get_env("GLOSSIA_MICROSANDBOX_IMAGE") || microsandbox_image_default,
  microsandbox_cpus: String.to_integer(System.get_env("GLOSSIA_MICROSANDBOX_CPUS") || "2"),
  microsandbox_memory: System.get_env("GLOSSIA_MICROSANDBOX_MEMORY") || "2G",
  microsandbox_repo_path: System.get_env("GLOSSIA_MICROSANDBOX_REPO_PATH") || "/tmp/glossia/repo",
  microsandbox_mounts:
    if(config_env() == :dev,
      do: [
        %{
          source: Path.expand("../tmp/dev-remotes", __DIR__),
          destination: "/mnt/glossia-remotes",
          read_only: true
        }
      ],
      else: []
    )

config :glossia, Glossia.Projects.Setup,
  harness_timeout_ms:
    String.to_integer(System.get_env("GLOSSIA_SETUP_HARNESS_TIMEOUT_MS") || "660000"),
  harness: System.get_env("GLOSSIA_SETUP_HARNESS") || "opencode",
  harness_command: System.get_env("GLOSSIA_SETUP_HARNESS_COMMAND") || "opencode",
  harness_model: System.get_env("GLOSSIA_SETUP_HARNESS_MODEL"),
  harness_agent: System.get_env("GLOSSIA_SETUP_HARNESS_AGENT"),
  harness_pure: System.get_env("GLOSSIA_SETUP_HARNESS_PURE", "true") not in ["false", "0"],
  harness_env: json_env.("GLOSSIA_SETUP_HARNESS_ENV_JSON", %{}),
  harness_context_path: System.get_env("GLOSSIA_SETUP_HARNESS_CONTEXT_PATH"),
  opencode_config: json_env.("GLOSSIA_SETUP_OPENCODE_CONFIG_JSON", %{}),
  minimax_api_key:
    System.get_env("GLOSSIA_SETUP_MINIMAX_API_KEY") || System.get_env("MINIMAX_API_KEY"),
  model: System.get_env("GLOSSIA_SETUP_MODEL"),
  local_remotes_dir: if(config_env() == :dev, do: Path.expand("../tmp/dev-remotes", __DIR__)),
  local_remotes_guest_dir: if(config_env() == :dev, do: "/mnt/glossia-remotes")

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
if not runner_child? and (System.get_env("GLOSSIA_PHX_SERVER") || System.get_env("PHX_SERVER")) do
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

  default_otel_service_name = if runner_child?, do: "glossia-runner", else: "glossia-web"
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

  repo_pool_size =
    if runner_child? do
      String.to_integer(System.get_env("GLOSSIA_FLAME_REPO_POOL_SIZE") || "1")
    else
      String.to_integer(System.get_env("GLOSSIA_POOL_SIZE") || "10")
    end

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

  clickhouse_pool_size =
    if runner_child? do
      String.to_integer(System.get_env("GLOSSIA_FLAME_CLICKHOUSE_POOL_SIZE") || "1")
    else
      String.to_integer(System.get_env("GLOSSIA_CLICKHOUSE_POOL_SIZE") || "5")
    end

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
end
