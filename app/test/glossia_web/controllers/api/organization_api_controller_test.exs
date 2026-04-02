defmodule GlossiaWeb.Api.OrganizationApiControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Organizations
  alias Glossia.TestHelpers

  @scopes ~w(account:read organization:read organization:write organization:delete members:read members:write)

  setup do
    Mimic.stub(Glossia.Mailer, :deliver, fn _email -> {:ok, %{}} end)

    admin = TestHelpers.create_user("orgapi-admin@test.com", "orgapi-admin")
    member = TestHelpers.create_user("orgapi-member@test.com", "orgapi-member")
    outsider = TestHelpers.create_user("orgapi-outsider@test.com", "orgapi-outsider")

    {:ok, %{account: org_account, organization: org}} =
      Organizations.create_organization(admin, %{
        handle: "orgapi-#{System.unique_integer([:positive])}",
        name: "Test Org"
      })

    Organizations.add_member(org, member, "member")

    %{
      admin: admin,
      member: member,
      outsider: outsider,
      org: org,
      org_account: org_account
    }
  end

  # -- Index --

  describe "GET /api/organizations" do
    test "lists organizations for the authenticated user", %{
      conn: conn,
      admin: admin,
      org_account: org_account
    } do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> get("/api/organizations")

      assert %{"organizations" => orgs} = json_response(conn, 200)
      handles = Enum.map(orgs, & &1["handle"])
      assert org_account.handle in handles
    end
  end

  # -- Show --

  describe "GET /api/organizations/:handle" do
    test "returns org details for a member", %{
      conn: conn,
      member: member,
      org_account: org_account
    } do
      conn =
        conn
        |> TestHelpers.authenticate(member, @scopes)
        |> get("/api/organizations/#{org_account.handle}")

      assert %{"handle" => handle, "name" => "Test Org", "type" => "organization"} =
               json_response(conn, 200)

      assert handle == org_account.handle
    end

    test "returns 403 for non-member", %{conn: conn, outsider: outsider, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(outsider, @scopes)
        |> get("/api/organizations/#{org_account.handle}")

      assert json_response(conn, 403)
    end

    test "returns 404 for unknown handle", %{conn: conn, admin: admin} do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> get("/api/organizations/nonexistent-org")

      assert json_response(conn, 404)
    end
  end

  # -- Update --

  describe "PATCH /api/organizations/:handle" do
    test "admin can update name", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> patch("/api/organizations/#{org_account.handle}", %{name: "Updated Name"})

      assert %{"name" => "Updated Name"} = json_response(conn, 200)
    end

    test "admin can update visibility", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> patch("/api/organizations/#{org_account.handle}", %{visibility: "public"})

      assert %{"visibility" => "public"} = json_response(conn, 200)
    end

    test "non-admin member cannot update", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(member, @scopes)
        |> patch("/api/organizations/#{org_account.handle}", %{name: "Nope"})

      assert json_response(conn, 403)
    end
  end

  # -- Delete --

  describe "DELETE /api/organizations/:handle" do
    test "admin can delete organization", %{conn: conn, admin: admin} do
      {:ok, %{account: acct}} =
        Organizations.create_organization(admin, %{
          handle: "deleteme-#{System.unique_integer([:positive])}",
          name: "Delete Me"
        })

      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> delete("/api/organizations/#{acct.handle}")

      assert response(conn, 204)
    end

    test "non-admin cannot delete", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(member, @scopes)
        |> delete("/api/organizations/#{org_account.handle}")

      assert json_response(conn, 403)
    end
  end

  # -- Members --

  describe "GET /api/organizations/:handle/members" do
    test "returns members for admin", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> get("/api/organizations/#{org_account.handle}/members")

      assert %{"members" => members} = json_response(conn, 200)
      assert length(members) == 2
    end

    test "returns members for member", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(member, @scopes)
        |> get("/api/organizations/#{org_account.handle}/members")

      assert %{"members" => _} = json_response(conn, 200)
    end

    test "returns 403 for outsider", %{conn: conn, outsider: outsider, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(outsider, @scopes)
        |> get("/api/organizations/#{org_account.handle}/members")

      assert json_response(conn, 403)
    end
  end

  describe "DELETE /api/organizations/:handle/members/:user_handle" do
    test "admin can remove a member", %{conn: conn, admin: admin, org_account: org_account} do
      removable = TestHelpers.create_user("removable@test.com", "removable")
      org = Organizations.get_organization_for_account(org_account)
      Organizations.add_member(org, removable, "member")

      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> delete("/api/organizations/#{org_account.handle}/members/#{removable.account.handle}")

      assert response(conn, 204)
    end

    test "cannot remove the sole admin", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> delete("/api/organizations/#{org_account.handle}/members/#{admin.account.handle}")

      assert %{"error" => error} = json_response(conn, 409)
      assert error =~ "only admin"
    end

    test "non-admin cannot remove members", %{
      conn: conn,
      member: member,
      org_account: org_account,
      admin: admin
    } do
      conn =
        conn
        |> TestHelpers.authenticate(member, @scopes)
        |> delete("/api/organizations/#{org_account.handle}/members/#{admin.account.handle}")

      assert json_response(conn, 403)
    end
  end

  # -- Invitations --

  describe "GET /api/organizations/:handle/invitations" do
    test "returns pending invitations", %{
      conn: conn,
      admin: admin,
      org: org,
      org_account: org_account
    } do
      {:ok, _} = Organizations.create_invitation(org, admin, %{"email" => "pending@test.com"})

      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> get("/api/organizations/#{org_account.handle}/invitations")

      assert %{"invitations" => invitations} = json_response(conn, 200)
      assert length(invitations) >= 1
    end
  end

  describe "POST /api/organizations/:handle/invitations" do
    test "admin can invite by email", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> post("/api/organizations/#{org_account.handle}/invitations", %{
          email: "newinvite@test.com"
        })

      assert %{"email" => "newinvite@test.com", "role" => "member", "status" => "pending"} =
               json_response(conn, 201)
    end

    test "returns conflict for existing member", %{
      conn: conn,
      admin: admin,
      member: member,
      org_account: org_account
    } do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> post("/api/organizations/#{org_account.handle}/invitations", %{email: member.email})

      assert %{"error" => error} = json_response(conn, 409)
      assert error =~ "already a member"
    end

    test "non-admin cannot invite", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> TestHelpers.authenticate(member, @scopes)
        |> post("/api/organizations/#{org_account.handle}/invitations", %{email: "nope@test.com"})

      assert json_response(conn, 403)
    end
  end

  describe "DELETE /api/organizations/:handle/invitations/:invitation_id" do
    test "admin can revoke an invitation", %{
      conn: conn,
      admin: admin,
      org: org,
      org_account: org_account
    } do
      {:ok, invitation} =
        Organizations.create_invitation(org, admin, %{"email" => "revokeme@test.com"})

      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> delete("/api/organizations/#{org_account.handle}/invitations/#{invitation.id}")

      assert response(conn, 204)
    end

    test "returns 404 for unknown invitation", %{
      conn: conn,
      admin: admin,
      org_account: org_account
    } do
      conn =
        conn
        |> TestHelpers.authenticate(admin, @scopes)
        |> delete("/api/organizations/#{org_account.handle}/invitations/#{Ecto.UUID.generate()}")

      assert json_response(conn, 404)
    end

    test "non-admin cannot revoke", %{
      conn: conn,
      member: member,
      org: org,
      admin: admin,
      org_account: org_account
    } do
      {:ok, invitation} =
        Organizations.create_invitation(org, admin, %{"email" => "revoke2@test.com"})

      conn =
        conn
        |> TestHelpers.authenticate(member, @scopes)
        |> delete("/api/organizations/#{org_account.handle}/invitations/#{invitation.id}")

      assert json_response(conn, 403)
    end
  end
end
