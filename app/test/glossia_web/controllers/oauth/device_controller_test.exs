defmodule GlossiaWeb.OAuth.DeviceControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Repo
  alias GlossiaWeb.ApiTestHelpers

  @device_grant_type "urn:ietf:params:oauth:grant-type:device_code"

  describe "POST /oauth/device_authorization" do
    test "issues a device_code and user_code for first-party clients", %{conn: conn} do
      client = create_client(first_party?: true)

      conn =
        post(conn, "/oauth/device_authorization", %{
          "client_id" => client.id,
          "scope" => "account:read project:read"
        })

      assert %{
               "device_code" => device_code,
               "user_code" => user_code,
               "verification_uri" => verification_uri,
               "verification_uri_complete" => verification_uri_complete,
               "expires_in" => expires_in,
               "interval" => interval
             } = json_response(conn, 200)

      assert is_binary(device_code) and byte_size(device_code) > 20
      assert String.match?(user_code, ~r/^[A-Z0-9]{4}-[A-Z0-9]{4}$/)
      assert String.ends_with?(verification_uri, "/oauth/device")
      assert String.contains?(verification_uri_complete, "user_code=#{user_code}")
      assert expires_in > 0
      assert interval > 0
    end

    test "rejects non-first-party clients", %{conn: conn} do
      client = create_client(first_party?: false)

      conn =
        post(conn, "/oauth/device_authorization", %{
          "client_id" => client.id,
          "scope" => "account:read"
        })

      assert %{"error" => "unauthorized_client"} = json_response(conn, 400)
    end
  end

  describe "POST /oauth/token (device flow)" do
    test "returns authorization_pending while approval has not happened", %{} do
      client = create_client(first_party?: true)
      %{"device_code" => device_code} = issue_device_code(build_conn(), client.id)

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => @device_grant_type,
          "client_id" => client.id,
          "device_code" => device_code
        })

      assert %{"error" => "authorization_pending"} = json_response(conn, 400)
    end

    test "returns slow_down when polling too fast", %{} do
      client = create_client(first_party?: true)
      %{"device_code" => device_code} = issue_device_code(build_conn(), client.id)

      _ =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => @device_grant_type,
          "client_id" => client.id,
          "device_code" => device_code
        })

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => @device_grant_type,
          "client_id" => client.id,
          "device_code" => device_code
        })

      assert %{"error" => "slow_down"} = json_response(conn, 400)
    end

    test "issues tokens after user approval", %{} do
      client = create_client(first_party?: true)
      user = ApiTestHelpers.create_user("oauth-device@test.com", "oauth-device")

      %{"device_code" => device_code, "user_code" => user_code} =
        issue_device_code(build_conn(), client.id)

      _approval_conn =
        build_conn()
        |> init_test_session(%{})
        |> put_session(:user_id, user.id)
        |> post("/oauth/device/confirm", %{"user_code" => user_code, "decision" => "approve"})

      conn =
        build_conn()
        |> post("/oauth/token", %{
          "grant_type" => @device_grant_type,
          "client_id" => client.id,
          "device_code" => device_code
        })

      assert %{
               "access_token" => access_token,
               "refresh_token" => refresh_token,
               "token_type" => "bearer",
               "expires_in" => expires_in
             } = json_response(conn, 200)

      assert is_binary(access_token)
      assert is_binary(refresh_token)
      assert expires_in > 0

      accounts_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> get("/api/accounts")

      assert %{"accounts" => accounts} = json_response(accounts_conn, 200)
      assert Enum.any?(accounts, fn account -> account["handle"] == user.account.handle end)
    end
  end

  describe "GET /.well-known/oauth-authorization-server" do
    test "advertises the device authorization endpoint and grant type", %{conn: conn} do
      conn = get(conn, "/.well-known/oauth-authorization-server")

      assert %{
               "device_authorization_endpoint" => device_authorization_endpoint,
               "grant_types_supported" => grant_types_supported
             } = json_response(conn, 200)

      assert String.ends_with?(device_authorization_endpoint, "/oauth/device_authorization")

      assert "urn:ietf:params:oauth:grant-type:device_code" in grant_types_supported
    end
  end

  defp issue_device_code(conn, client_id) do
    conn
    |> post("/oauth/device_authorization", %{
      "client_id" => client_id,
      "scope" => "account:read project:read"
    })
    |> json_response(200)
  end

  defp create_client(opts) do
    first_party? = Keyword.get(opts, :first_party?, false)
    metadata = if first_party?, do: %{"first_party" => true, "device_flow" => true}, else: %{}

    {:ok, client} =
      Boruta.Ecto.Admin.create_client(%{
        name: "device-client-#{System.unique_integer([:positive])}",
        redirect_uris: ["https://glossia.ai/oauth/device"],
        supported_grant_types: ["authorization_code", "refresh_token", "revoke"],
        authorize_scope: true,
        confidential: false,
        pkce: true,
        public_refresh_token: true,
        public_revoke: true,
        metadata: metadata
      })

    # Ensure no stale cache between tests when client metadata changes.
    Repo.preload(client, :authorized_scopes)
  end
end
