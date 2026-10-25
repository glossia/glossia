defmodule GlossiaWeb.OAuth.RegisterControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.TestHelpers

  @redirect_uri "glossia://oauth/callback"

  test "a dynamically registered public client exchanges PKCE codes and refreshes without a secret" do
    registration =
      build_conn()
      |> post(~p"/oauth/register", %{
        "client_name" => "Glossia Mobile",
        "redirect_uris" => [@redirect_uri],
        "grant_types" => ["authorization_code", "refresh_token"],
        "token_endpoint_auth_method" => "none"
      })
      |> json_response(201)

    assert registration["token_endpoint_auth_method"] == "none"
    refute Map.has_key?(registration, "client_secret")
    refute "client_credentials" in registration["grant_types"]

    user = TestHelpers.create_user("mobile-registration@example.com", "mobile-registration")
    verifier = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
    challenge = Base.url_encode64(:crypto.hash(:sha256, verifier), padding: false)

    authorization = %{
      "client_id" => registration["client_id"],
      "redirect_uri" => @redirect_uri,
      "response_type" => "code",
      "state" => "native-state",
      "scope" => "organization:read project:read voice:read glossary:read",
      "code_challenge" => challenge,
      "code_challenge_method" => "S256"
    }

    missing_pkce =
      build_conn()
      |> init_test_session(%{user_id: user.id})
      |> post(
        ~p"/oauth/authorize",
        Map.drop(authorization, ["code_challenge", "code_challenge_method"])
      )

    assert json_response(missing_pkce, 400)["error"] == "invalid_request"

    callback =
      build_conn()
      |> init_test_session(%{user_id: user.id})
      |> post(~p"/oauth/authorize", authorization)
      |> redirected_to()
      |> URI.parse()

    params = URI.decode_query(callback.query)
    assert params["state"] == "native-state"

    token_request = %{
      "grant_type" => "authorization_code",
      "client_id" => registration["client_id"],
      "redirect_uri" => @redirect_uri,
      "code" => params["code"],
      "code_verifier" => verifier
    }

    tokens = build_conn() |> post(~p"/oauth/token", token_request) |> json_response(200)
    assert is_binary(tokens["access_token"])
    assert is_binary(tokens["refresh_token"])

    organizations =
      build_conn()
      |> put_req_header("authorization", "Bearer #{tokens["access_token"]}")
      |> get(~p"/api/organizations")
      |> json_response(200)

    assert is_list(organizations["organizations"])

    refreshed =
      build_conn()
      |> post(~p"/oauth/token", %{
        "grant_type" => "refresh_token",
        "client_id" => registration["client_id"],
        "refresh_token" => tokens["refresh_token"]
      })
      |> json_response(200)

    assert is_binary(refreshed["access_token"])
    assert refreshed["access_token"] != tokens["access_token"]
  end

  test "confidential registration retains its secret-based authentication", %{conn: conn} do
    registration =
      conn
      |> post(~p"/oauth/register", %{
        "client_name" => "Confidential integration",
        "redirect_uris" => ["https://example.com/oauth/callback"],
        "token_endpoint_auth_method" => "client_secret_post"
      })
      |> json_response(201)

    assert registration["token_endpoint_auth_method"] == "client_secret_post"
    assert is_binary(registration["client_secret"])
    assert byte_size(registration["client_secret"]) > 0
  end
end
