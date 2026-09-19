defmodule BabelWeb.MCPOAuthDiscoveryTest do
  use BabelWeb.ConnCase, async: true

  test "publishes OAuth discovery for the Babel operations server", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> get(~p"/.well-known/oauth-authorization-server")

    response = json_response(conn, :ok)

    assert response["issuer"] == "http://localhost:4060"
    assert response["authorization_endpoint"] == "http://localhost:4060/oauth/authorize"
    assert response["token_endpoint"] == "http://localhost:4060/oauth/token"
    assert response["registration_endpoint"] == "http://localhost:4060/oauth/register"
    assert response["scopes_supported"] == ["operations:read", "operations:write"]
    assert response["token_endpoint_auth_methods_supported"] == ["none"]
  end

  test "challenges unauthenticated MCP requests with protected resource metadata", %{conn: conn} do
    conn = conn |> put_req_header("accept", "application/json") |> post(~p"/mcp", %{})

    assert response(conn, :unauthorized) == ~s({"error":"unauthorized"})

    assert get_resp_header(conn, "www-authenticate") == [
             ~s(Bearer resource_metadata="#{protected_resource_metadata_url()}")
           ]
  end

  defp protected_resource_metadata_url do
    BabelWeb.Endpoint.url()
    |> URI.merge("/.well-known/oauth-protected-resource/mcp")
    |> URI.to_string()
  end
end
