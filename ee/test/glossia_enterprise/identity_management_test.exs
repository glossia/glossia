defmodule GlossiaEnterprise.IdentityManagementTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic
  alias Glossia.{Organizations, Repo, TestHelpers}
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication

  alias GlossiaEnterprise.MCP.{
    GetOrganizationAuthenticationTool,
    UpdateOrganizationAuthenticationTool,
    VerifyOrganizationAuthenticationTool
  }

  alias Hermes.Server.Frame

  setup do
    admin = TestHelpers.create_user("identity-admin@example.test", "identity-admin")
    member = TestHelpers.create_user("identity-member@example.test", "identity-member")

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(admin, %{
        handle: "identity-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, member)
    %{admin: admin, member: member, organization: organization, account: account}
  end

  defp attrs do
    %{
      "auth_provider" => "oauth2",
      "auth_domain" => "identity-#{System.unique_integer([:positive])}.test",
      "auth_issuer" => "https://id.example.com",
      "auth_client_id" => "client-identity",
      "auth_client_secret" => "private-identity-secret",
      "auth_authorize_url" => "https://id.example.com/authorize",
      "auth_token_url" => "https://id.example.com/token",
      "auth_userinfo_url" => "https://id.example.com/userinfo"
    }
  end

  test "REST and MCP share configuration, retain secrets, and require admin membership and scope",
       %{conn: conn, admin: admin, member: member, account: account, organization: organization} do
    path = ~p"/api/organizations/#{account.handle}/authentication"
    conn = TestHelpers.authenticate(conn, admin, ["organization:admin"])
    response = conn |> patch(path, attrs()) |> json_response(200)
    assert response["auth_provider"] == "oauth2"
    assert response["auth_client_secret_configured"]
    refute Map.has_key?(response, "auth_client_secret")

    assert response["verification_record"]["name"] ==
             "_glossia-verification.#{response["auth_domain"]}"

    assert response["callback_url"] == Authentication.callback_url()

    paths = GlossiaWeb.OpenApiSpec.spec()["paths"]
    operation = paths["/api/organizations/{handle}/authentication"]["patch"]
    assert operation["security"] == [%{"oauth2" => ["organization:admin"]}]

    assert operation["requestBody"]["content"]["application/json"]["schema"]["properties"][
             "auth_client_secret"
           ]["writeOnly"]

    tools = Enum.map(Glossia.MCP.Server.__components__(:tool), & &1.name)
    assert "get_organization_authentication" in tools
    assert "update_organization_authentication" in tools
    assert "verify_organization_authentication" in tools

    frame = Frame.new(%{current_user: admin, scopes: ["organization:admin"]})
    params = %{"handle" => account.handle}
    assert {:reply, reply, _} = GetOrganizationAuthenticationTool.execute(params, frame)
    assert JSON.decode!(hd(reply.content)["text"]) == response

    assert {:reply, reply, _} =
             UpdateOrganizationAuthenticationTool.execute(
               Map.merge(params, %{
                 "auth_client_id" => "updated-client",
                 "auth_client_secret" => ""
               }),
               frame
             )

    assert JSON.decode!(hd(reply.content)["text"])["auth_client_id"] == "updated-client"

    assert Organizations.get_organization(organization.id).auth_client_secret ==
             "private-identity-secret"

    assert conn |> get(path) |> json_response(200) |> Map.fetch!("auth_client_id") ==
             "updated-client"

    for {user, scopes} <- [{admin, ["organization:write"]}, {member, ["organization:admin"]}] do
      denied = build_conn() |> TestHelpers.authenticate(user, scopes)
      assert denied |> get(path) |> json_response(403)
      assert denied |> patch(path, %{"auth_provider" => ""}) |> json_response(403)

      assert denied
             |> post(~p"/api/organizations/#{account.handle}/authentication/verify")
             |> json_response(403)

      denied_frame = Frame.new(%{current_user: user, scopes: scopes})
      assert {:error, _, _} = GetOrganizationAuthenticationTool.execute(params, denied_frame)
      assert {:error, _, _} = UpdateOrganizationAuthenticationTool.execute(params, denied_frame)
      assert {:error, _, _} = VerifyOrganizationAuthenticationTool.execute(params, denied_frame)
    end
  end

  test "remote configuration cannot enable untested SSO and recovery edits are atomic", %{
    conn: conn,
    admin: admin,
    organization: organization,
    account: account
  } do
    {:ok, saved} = Authentication.save(organization, admin, attrs())

    {:ok, verified} =
      Authentication.verify(saved, admin, fn _ -> {:ok, [Authentication.record_value(saved)]} end)

    conn = TestHelpers.authenticate(conn, admin, ["organization:admin"])
    path = ~p"/api/organizations/#{account.handle}/authentication"

    rejected =
      conn
      |> patch(path, %{"auth_client_id" => "rejected", "sso_enforced" => true})
      |> json_response(422)

    assert rejected["error"] == "sso_required"
    assert Organizations.get_organization(organization.id).auth_client_id == "client-identity"

    assert {:ok, true} =
             Authentication.set_enforcement(
               verified,
               admin,
               true,
               Authentication.session_proof(verified, admin)
             )

    assert conn |> patch(path, %{"auth_client_id" => "rejected"}) |> json_response(422) == %{
             "error" => "enforcement_enabled"
           }

    assert conn
           |> patch(path, %{"sso_enforced" => false, "auth_token_url" => "http://localhost/token"})
           |> json_response(422)

    assert Authentication.enforced?(verified)

    assert conn
           |> patch(path, %{"sso_enforced" => false, "auth_client_id" => "recovered"})
           |> json_response(200)
           |> Map.fetch!("sso_enforced") == false

    assert Organizations.get_organization(organization.id).auth_client_id == "recovered"
    frame = Frame.new(%{current_user: admin, scopes: ["organization:admin"]})

    assert {:error, _, _} =
             UpdateOrganizationAuthenticationTool.execute(
               %{"handle" => account.handle, "sso_enforced" => true},
               frame
             )

    assert conn
           |> post(~p"/api/organizations/#{account.handle}/authentication/verify")
           |> json_response(422) == %{"error" => "verification_failed"}

    assert {:error, _, _} =
             VerifyOrganizationAuthenticationTool.execute(%{"handle" => account.handle}, frame)
  end

  test "custom endpoints invalidate login proofs and provider changes erase custom settings", %{
    admin: admin,
    organization: organization
  } do
    {:ok, saved} = Authentication.save(organization, admin, attrs())

    {:ok, verified} =
      Authentication.verify(saved, admin, fn _ -> {:ok, [Authentication.record_value(saved)]} end)

    fingerprint = Authentication.provider_fingerprint(verified)
    proof = Authentication.session_proof(verified, admin)

    {:ok, changed} =
      Authentication.save(verified, admin, %{
        "auth_userinfo_url" => "https://id.example.com/new-userinfo"
      })

    refute Authentication.session_proof(changed, admin) == proof

    assert {:error, :invalid_identity} =
             Authentication.sign_in(
               changed,
               %{
                 user: %{
                   "sub" => "subject",
                   "email" => "new@#{verified.auth_domain}",
                   "email_verified" => true
                 }
               },
               fingerprint: fingerprint
             )

    {:ok, cleared} = Authentication.save(changed, admin, %{"auth_provider" => "google"})
    assert Authentication.settings(cleared).auth_userinfo_url == nil
    assert Repo.get!(Glossia.Accounts.Organization, organization.id).auth_client_secret == nil
  end

  test "changing an OAuth2 authority cannot impersonate identities linked to the old provider", %{
    admin: admin,
    organization: organization
  } do
    attrs = attrs()
    {:ok, saved} = Authentication.save(organization, admin, attrs)

    {:ok, verified} =
      Authentication.verify(saved, admin, fn _ -> {:ok, [Authentication.record_value(saved)]} end)

    victim = TestHelpers.create_user("victim@#{verified.auth_domain}", "identity-victim")
    {:ok, _} = Organizations.add_member(verified, victim)

    response = %{
      user: %{"sub" => "predictable-subject", "email" => victim.email, "email_verified" => true},
      token: %{}
    }

    assert {:ok, %{id: id}} = Authentication.sign_in(verified, response, link_user_id: victim.id)
    assert id == victim.id

    for field <- ~w(auth_authorize_url auth_token_url auth_userinfo_url auth_client_id) do
      replacement =
        if field == "auth_client_id", do: "other-client", else: "https://evil.test/idp"

      {:ok, changed} = Authentication.save(verified, admin, %{field => replacement})
      assert {:error, :identity_not_linked} = Authentication.sign_in(changed, response)

      {:ok, restored} = Authentication.save(changed, admin, %{field => attrs[field]})
      assert {:ok, %{id: ^id}} = Authentication.sign_in(restored, response)
    end

    {:ok, rotated} = Authentication.save(verified, admin, %{"auth_client_secret" => "rotated"})
    assert {:ok, %{id: ^id}} = Authentication.sign_in(rotated, response)
  end

  test "private attachments require browser SSO without relying on a handle URL", %{
    conn: conn,
    admin: admin,
    organization: organization,
    account: account
  } do
    {:ok, saved} = Authentication.save(organization, admin, attrs())

    {:ok, verified} =
      Authentication.verify(saved, admin, fn _ -> {:ok, [Authentication.record_value(saved)]} end)

    {:ok, discussion} =
      Glossia.Discussions.create_discussion(account, admin, %{title: "Private", body: "Private"})

    stub(Glossia.Storage, :download, fn _ -> {:ok, %{body: "private-image-bytes"}} end)
    path = ~p"/uploads/#{[account.id, "discussions", discussion.id, "image.png"]}"
    ordinary = init_test_session(conn, %{user_id: admin.id})
    assert ordinary |> get(path) |> response(200) == "private-image-bytes"
    proof = Authentication.session_proof(verified, admin)
    assert {:ok, true} = Authentication.set_enforcement(verified, admin, true, proof)
    assert ordinary |> get(path) |> redirected_to() == ~p"/auth/login"

    authorized =
      init_test_session(conn, %{user_id: admin.id, organization_sso: proof}) |> get(path)

    assert response(authorized, 200) == "private-image-bytes"
    assert get_resp_header(authorized, "cache-control") == ["private, no-store"]
  end
end
