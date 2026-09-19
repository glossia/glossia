defmodule BabelWeb.OAuth.RegisterControllerTest do
  use BabelWeb.ConnCase, async: true

  test "registers a public PKCE client for the authorization code flow", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post(~p"/oauth/register", %{
        "client_name" => "Hermes",
        "redirect_uris" => ["http://127.0.0.1:8642/callback"],
        "grant_types" => ["client_credentials"]
      })

    response = json_response(conn, :created)

    assert is_binary(response["client_id"])
    assert response["redirect_uris"] == ["http://127.0.0.1:8642/callback"]
    assert response["grant_types"] == ["authorization_code", "refresh_token"]
    assert response["token_endpoint_auth_method"] == "none"
  end

  test "rejects a non-loopback HTTP redirect URI", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post(~p"/oauth/register", %{
        "redirect_uris" => ["http://example.com/callback"]
      })

    response = json_response(conn, :bad_request)

    assert response["error"] == "invalid_client_metadata"
    assert response["error_description"] =~ "loopback"
  end
end
