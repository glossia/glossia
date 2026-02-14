defmodule GlossiaWeb.WellKnownController do
  use GlossiaWeb, :controller

  def oauth_authorization_server(conn, _params) do
    issuer = Boruta.Config.issuer()

    scopes_supported =
      Glossia.Policy.list_rules()
      |> Enum.map(fn rule -> "#{rule.object}:#{rule.action}" end)

    json(conn, %{
      issuer: issuer,
      authorization_endpoint: "#{issuer}/oauth/authorize",
      token_endpoint: "#{issuer}/oauth/token",
      revocation_endpoint: "#{issuer}/oauth/revoke",
      introspection_endpoint: "#{issuer}/oauth/introspect",
      registration_endpoint: "#{issuer}/oauth/register",
      scopes_supported: scopes_supported,
      response_types_supported: ["code"],
      grant_types_supported: ["authorization_code", "refresh_token"],
      code_challenge_methods_supported: ["S256"]
    })
  end

  def oauth_protected_resource(conn, _params) do
    issuer = Boruta.Config.issuer()

    scopes_supported =
      Glossia.Policy.list_rules()
      |> Enum.map(fn rule -> "#{rule.object}:#{rule.action}" end)

    json(conn, %{
      resource: issuer,
      authorization_servers: [issuer],
      scopes_supported: scopes_supported,
      bearer_methods_supported: ["header"]
    })
  end
end
