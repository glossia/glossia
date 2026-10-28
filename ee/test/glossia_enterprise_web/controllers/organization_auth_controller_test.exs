defmodule GlossiaEnterpriseWeb.OrganizationAuthControllerTest do
  use GlossiaWeb.ConnCase, async: false
  alias Glossia.{Accounts, Organizations, TestHelpers}
  alias GlossiaEnterprise.OrganizationAuthentication

  defmodule Provider do
    def authorize_url(config) do
      {:ok,
       %{
         url: "https://accounts.google.com/login",
         session_params: %{state: "expected", domain: config[:authorization_params][:hd]}
       }}
    end

    def callback(config, params), do: callback(config, params, config[:session_params])

    def callback(_config, %{"state" => "expected"}, %{state: "expected", domain: domain}) do
      {:ok,
       %{
         user: %{
           "sub" => "subject",
           "email" => "teammate@#{domain}",
           "email_verified" => true,
           "hd" => domain
         },
         token: %{}
       }}
    end

    def callback(_, _, _), do: {:error, :invalid_state}
  end

  setup %{conn: conn} do
    old = Application.get_env(:glossia, :oauth_providers)

    Application.put_env(:glossia, :oauth_providers,
      google: [client_id: "client", client_secret: "secret", strategy: Provider]
    )

    on_exit(fn -> Application.put_env(:glossia, :oauth_providers, old || []) end)
    admin = TestHelpers.create_user("admin@example.test", "admin")

    {:ok, %{organization: organization}} =
      Organizations.create_organization(admin, %{
        handle: "auth-#{System.unique_integer([:positive])}"
      })

    domain = "team-#{System.unique_integer([:positive])}.test"

    {:ok, organization} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "google",
        "auth_domain" => domain
      })

    {:ok, organization} =
      OrganizationAuthentication.verify(organization, admin, fn _ ->
        {:ok, [OrganizationAuthentication.record_value(organization)]}
      end)

    unique = System.unique_integer([:positive])

    %{
      conn: %{conn | remote_ip: {10, 3, rem(div(unique, 256), 256), rem(unique, 256)}},
      organization: organization,
      admin: admin
    }
  end

  test "work email routes to the provider and creates a basic member", %{
    conn: conn,
    organization: organization
  } do
    conn =
      post(conn, ~p"/auth/organization",
        organization: %{email: "teammate@#{organization.auth_domain}"}
      )

    assert redirected_to(conn) == "https://accounts.google.com/login"
    assert get_session(conn, :organization_auth)
    conn = conn |> recycle() |> get(~p"/auth/organization/callback", state: "expected")
    assert redirected_to(conn) == ~p"/#{organization.account.handle}"
    user = Accounts.get_user(get_session(conn, :user_id))

    assert Organizations.get_membership(organization, user).scopes ==
             Glossia.MemberPermissions.basic_scopes()

    refute get_session(conn, :organization_auth)
    replay = conn |> recycle() |> get(~p"/auth/organization/callback", state: "expected")
    assert redirected_to(replay) == ~p"/auth/login"
  end

  test "rejects mismatched state and consumes the attempt", %{
    conn: conn,
    organization: organization
  } do
    conn =
      post(conn, ~p"/auth/organization",
        organization: %{email: "teammate@#{organization.auth_domain}"}
      )

    conn = conn |> recycle() |> get(~p"/auth/organization/callback", state: "wrong")
    assert redirected_to(conn) == ~p"/auth/login"
    refute get_session(conn, :user_id)
    refute get_session(conn, :organization_auth)
  end

  test "configuration changes invalidate callbacks", %{
    conn: conn,
    organization: organization,
    admin: admin
  } do
    conn =
      post(conn, ~p"/auth/organization",
        organization: %{email: "teammate@#{organization.auth_domain}"}
      )

    {:ok, _} = OrganizationAuthentication.save(organization, admin, %{"auth_provider" => ""})
    conn = conn |> recycle() |> get(~p"/auth/organization/callback", state: "expected")
    assert redirected_to(conn) == ~p"/auth/login"
    refute get_session(conn, :user_id)
  end

  test "custom OAuth2 exchanges authorization codes with PKCE and accepts only verified work identities",
       %{conn: conn, organization: organization, admin: admin} do
    {:ok, organization} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "oauth2",
        "auth_issuer" => "https://8.8.8.8",
        "auth_client_id" => "custom-client",
        "auth_client_secret" => "custom-secret",
        "auth_authorize_url" => "https://8.8.8.8/authorize",
        "auth_token_url" => "https://8.8.8.8/token",
        "auth_userinfo_url" => "https://8.8.8.8/userinfo"
      })

    {:ok, organization} =
      OrganizationAuthentication.verify(organization, admin, fn _ ->
        {:ok, [OrganizationAuthentication.record_value(organization)]}
      end)

    conn =
      post(conn, ~p"/auth/organization",
        organization: %{email: "custom@#{organization.auth_domain}"}
      )

    uri = conn |> redirected_to() |> URI.parse()
    query = URI.decode_query(uri.query)
    assert uri.path == "/authorize"
    assert query["code_challenge_method"] == "S256"
    assert query["scope"] == "openid email profile"

    Mimic.expect(Req, :request, fn opts ->
      assert opts[:method] == :post
      body = URI.decode_query(opts[:body])
      assert body["code"] == "custom-code"

      assert Base.url_encode64(:crypto.hash(:sha256, body["code_verifier"]), padding: false) ==
               query["code_challenge"]

      {:ok,
       %Req.Response{
         status: 200,
         headers: %{"content-type" => ["application/json"]},
         body: Jason.encode!(%{access_token: "custom-access", token_type: "Bearer"})
       }}
    end)

    Mimic.expect(Req, :request, fn opts ->
      assert opts[:method] == :get
      assert opts[:url] == "https://8.8.8.8/userinfo"

      {:ok,
       %Req.Response{
         status: 200,
         headers: %{"content-type" => ["application/json"]},
         body:
           Jason.encode!(%{
             sub: "custom-sub",
             email: "custom@#{organization.auth_domain}",
             email_verified: true,
             name: "Custom User"
           })
       }}
    end)

    conn =
      conn
      |> recycle()
      |> get(~p"/auth/organization/callback", state: query["state"], code: "custom-code")

    assert redirected_to(conn) == ~p"/#{organization.account.handle}"
    user = Accounts.get_user(get_session(conn, :user_id))
    assert user.email == "custom@#{organization.auth_domain}"

    assert get_session(conn, :organization_sso) ==
             OrganizationAuthentication.session_proof(organization, user)

    for verified <- [false, "true", nil] do
      assert {:error, :invalid_identity} =
               OrganizationAuthentication.sign_in(organization, %{
                 user: %{"sub" => "invalid", "email" => user.email, "email_verified" => verified}
               })
    end
  end

  test "unknown domains cannot start organization sign-in", %{conn: conn} do
    conn = post(conn, ~p"/auth/organization", organization: %{email: "person@unknown.test"})
    assert redirected_to(conn) == ~p"/auth/login"
    refute get_session(conn, :organization_auth)
  end
end
