defmodule BabelWeb.WellKnownController do
  use BabelWeb, :controller

  @operations_read_scope "operations:read"
  @operations_write_scope "operations:write"

  def oauth_authorization_server(conn, _params) do
    issuer = Boruta.Config.issuer()

    json(conn, %{
      issuer: issuer,
      authorization_endpoint: endpoint_url(issuer, "/oauth/authorize"),
      token_endpoint: endpoint_url(issuer, "/oauth/token"),
      registration_endpoint: endpoint_url(issuer, "/oauth/register"),
      scopes_supported: [@operations_read_scope, @operations_write_scope],
      response_types_supported: ["code"],
      grant_types_supported: ["authorization_code", "refresh_token"],
      token_endpoint_auth_methods_supported: ["none"],
      code_challenge_methods_supported: ["S256"]
    })
  end

  def oauth_protected_resource(conn, _params) do
    issuer = Boruta.Config.issuer()

    json(conn, %{
      resource: endpoint_url(issuer, "/mcp"),
      authorization_servers: [issuer],
      scopes_supported: [@operations_read_scope, @operations_write_scope],
      bearer_methods_supported: ["header"]
    })
  end

  defp endpoint_url(issuer, path) do
    issuer
    |> URI.merge(path)
    |> URI.to_string()
  end
end
