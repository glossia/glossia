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
stripe_meter_event_name =
  System.get_env("STRIPE_METER_EVENT_NAME") ||
    # Default for a single "usage credits" meter. Create the Stripe meter with
    # this same event name (in both test + live modes).
    "glossia_usage_credits"

stripe_enabled =
  case System.get_env("STRIPE_ENABLED") do
    "true" -> true
    "1" -> true
    "false" -> false
    "0" -> false
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
            strategy: Assent.Strategy.Gitlab
          )

        _ ->
          providers
      end
    end)

  if oauth_providers != [] do
    config :glossia, :oauth_providers, oauth_providers
  end

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

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :glossia, Glossia.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
