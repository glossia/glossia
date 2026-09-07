defmodule GlossiaWeb.WellKnownController do
  use GlossiaWeb, :controller

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "well_known",
    scale: :timer.minutes(1),
    limit: 120,
    by: :ip

  def oauth_authorization_server(conn, _params) do
    issuer = Boruta.Config.issuer()

    scopes_supported = Glossia.Authz.available_scopes()

    json(conn, %{
      issuer: issuer,
      authorization_endpoint: "#{issuer}/oauth/authorize",
      device_authorization_endpoint: "#{issuer}/oauth/device_authorization",
      token_endpoint: "#{issuer}/oauth/token",
      revocation_endpoint: "#{issuer}/oauth/revoke",
      introspection_endpoint: "#{issuer}/oauth/introspect",
      registration_endpoint: "#{issuer}/oauth/register",
      scopes_supported: scopes_supported,
      response_types_supported: ["code"],
      grant_types_supported: [
        "authorization_code",
        "refresh_token",
        "urn:ietf:params:oauth:grant-type:device_code"
      ],
      code_challenge_methods_supported: ["S256"]
    })
  end

  def oauth_protected_resource(conn, _params) do
    issuer = Boruta.Config.issuer()

    scopes_supported = Glossia.Authz.available_scopes()

    json(conn, %{
      resource: issuer,
      authorization_servers: [issuer],
      scopes_supported: scopes_supported,
      bearer_methods_supported: ["header"]
    })
  end
end
