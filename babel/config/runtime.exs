import Config

config :babel, Babel.GoToMarket.Search.Tavily, api_key: System.get_env("BABEL_TAVILY_API_KEY")

config :babel, BabelWeb.Endpoint,
  http: [
    port:
      String.to_integer(System.get_env("PORT") || System.get_env("BABEL_SERVER_PORT") || "4060")
  ]

if config_env() == :dev do
  if postgres_db = System.get_env("BABEL_POSTGRES_DB") do
    config :babel, Babel.Repo, database: postgres_db
  end

  if server_url = System.get_env("BABEL_SERVER_URL") do
    config :boruta, Boruta.Oauth, issuer: server_url
  end
end

if config_env() == :test do
  if postgres_db = System.get_env("BABEL_TEST_POSTGRES_DB") do
    config :babel, Babel.Repo, database: postgres_db
  end

  if test_port = System.get_env("BABEL_TEST_PORT") do
    config :babel, BabelWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: String.to_integer(test_port)]
  end
end

if config_env() == :prod do
  database_url = System.fetch_env!("BABEL_DATABASE_URL")
  secret_key_base = System.fetch_env!("BABEL_SECRET_KEY_BASE")
  host = System.get_env("BABEL_HOST") || "babel.glossia.ai"

  config :babel, Babel.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :babel, BabelWeb.Endpoint,
    url: [host: host, scheme: "https", port: 443],
    http: [port: String.to_integer(System.get_env("PORT") || "4060")],
    secret_key_base: secret_key_base,
    server: System.get_env("BABEL_PHX_SERVER") == "true" || System.get_env("PHX_SERVER") == "true"

  config :babel, :dns_cluster_query, System.get_env("BABEL_DNS_CLUSTER_QUERY") || :ignore

  config :babel, Babel.Glossia,
    base_url: System.get_env("BABEL_GLOSSIA_INTERNAL_URL"),
    token_path: System.get_env("BABEL_GLOSSIA_TOKEN_PATH"),
    tls_server_name: System.get_env("BABEL_GLOSSIA_TLS_SERVER_NAME"),
    receive_timeout:
      String.to_integer(System.get_env("BABEL_GLOSSIA_RECEIVE_TIMEOUT_MS") || "30000")

  config :babel, BabelWeb.Plugs.PomeriumAuth,
    enabled: true,
    email_domain: "glossia.ai",
    expected_issuer: "babel.glossia.ai",
    expected_audience: "babel.glossia.ai",
    jwks_url: "https://babel.glossia.ai/.well-known/pomerium/jwks.json"

  config :boruta, Boruta.Oauth, issuer: "https://#{host}"
end
