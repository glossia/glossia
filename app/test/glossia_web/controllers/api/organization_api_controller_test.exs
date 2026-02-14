defmodule GlossiaWeb.Api.OrganizationApiControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Accounts
  alias Glossia.Accounts.{Account, User}
  alias Glossia.Repo

  setup do
    Mimic.stub(Glossia.Mailer, :deliver, fn _email -> {:ok, %{}} end)

    admin = create_user("orgapi-admin@test.com", "orgapi-admin")
    member = create_user("orgapi-member@test.com", "orgapi-member")
    outsider = create_user("orgapi-outsider@test.com", "orgapi-outsider")

    {:ok, %{account: org_account, organization: org}} =
      Accounts.create_organization(admin, %{
        handle: "orgapi-#{System.unique_integer([:positive])}",
        name: "Test Org"
      })

    Accounts.add_member(org, member, "member")

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
        |> authenticate(admin)
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
        |> authenticate(member)
        |> get("/api/organizations/#{org_account.handle}")

      assert %{"handle" => handle, "name" => "Test Org", "type" => "organization"} =
               json_response(conn, 200)

      assert handle == org_account.handle
    end

    test "returns 403 for non-member", %{conn: conn, outsider: outsider, org_account: org_account} do
      conn =
        conn
        |> authenticate(outsider)
        |> get("/api/organizations/#{org_account.handle}")

      assert json_response(conn, 403)
    end

    test "returns 404 for unknown handle", %{conn: conn, admin: admin} do
      conn =
        conn
        |> authenticate(admin)
        |> get("/api/organizations/nonexistent-org")

      assert json_response(conn, 404)
    end
  end

  # -- Update --

  describe "PATCH /api/organizations/:handle" do
    test "admin can update name", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> authenticate(admin)
        |> patch("/api/organizations/#{org_account.handle}", %{name: "Updated Name"})

      assert %{"name" => "Updated Name"} = json_response(conn, 200)
    end

    test "admin can update visibility", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> authenticate(admin)
        |> patch("/api/organizations/#{org_account.handle}", %{visibility: "public"})

      assert %{"visibility" => "public"} = json_response(conn, 200)
    end

    test "non-admin member cannot update", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> authenticate(member)
        |> patch("/api/organizations/#{org_account.handle}", %{name: "Nope"})

      assert json_response(conn, 403)
    end
  end

  # -- Delete --

  describe "DELETE /api/organizations/:handle" do
    test "admin can delete organization", %{conn: conn, admin: admin} do
      {:ok, %{account: acct}} =
        Accounts.create_organization(admin, %{
          handle: "deleteme-#{System.unique_integer([:positive])}",
          name: "Delete Me"
        })

      conn =
        conn
        |> authenticate(admin)
        |> delete("/api/organizations/#{acct.handle}")

      assert response(conn, 204)
    end

    test "non-admin cannot delete", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> authenticate(member)
        |> delete("/api/organizations/#{org_account.handle}")

      assert json_response(conn, 403)
    end
  end

  # -- Members --

  describe "GET /api/organizations/:handle/members" do
    test "returns members for admin", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> authenticate(admin)
        |> get("/api/organizations/#{org_account.handle}/members")

      assert %{"members" => members} = json_response(conn, 200)
      assert length(members) == 2
    end

    test "returns members for member", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> authenticate(member)
        |> get("/api/organizations/#{org_account.handle}/members")

      assert %{"members" => _} = json_response(conn, 200)
    end

    test "returns 403 for outsider", %{conn: conn, outsider: outsider, org_account: org_account} do
      conn =
        conn
        |> authenticate(outsider)
        |> get("/api/organizations/#{org_account.handle}/members")

      assert json_response(conn, 403)
    end
  end

  describe "DELETE /api/organizations/:handle/members/:user_handle" do
    test "admin can remove a member", %{conn: conn, admin: admin, org_account: org_account} do
      removable = create_user("removable@test.com", "removable")
      org = Accounts.get_organization_for_account(org_account)
      Accounts.add_member(org, removable, "member")

      conn =
        conn
        |> authenticate(admin)
        |> delete("/api/organizations/#{org_account.handle}/members/#{removable.account.handle}")

      assert response(conn, 204)
    end

    test "cannot remove the sole admin", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> authenticate(admin)
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
        |> authenticate(member)
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
      {:ok, _} = Accounts.create_invitation(org, admin, %{"email" => "pending@test.com"})

      conn =
        conn
        |> authenticate(admin)
        |> get("/api/organizations/#{org_account.handle}/invitations")

      assert %{"invitations" => invitations} = json_response(conn, 200)
      assert length(invitations) >= 1
    end
  end

  describe "POST /api/organizations/:handle/invitations" do
    test "admin can invite by email", %{conn: conn, admin: admin, org_account: org_account} do
      conn =
        conn
        |> authenticate(admin)
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
        |> authenticate(admin)
        |> post("/api/organizations/#{org_account.handle}/invitations", %{email: member.email})

      assert %{"error" => error} = json_response(conn, 409)
      assert error =~ "already a member"
    end

    test "non-admin cannot invite", %{conn: conn, member: member, org_account: org_account} do
      conn =
        conn
        |> authenticate(member)
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
        Accounts.create_invitation(org, admin, %{"email" => "revokeme@test.com"})

      conn =
        conn
        |> authenticate(admin)
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
        |> authenticate(admin)
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
      {:ok, invitation} = Accounts.create_invitation(org, admin, %{"email" => "revoke2@test.com"})

      conn =
        conn
        |> authenticate(member)
        |> delete("/api/organizations/#{org_account.handle}/invitations/#{invitation.id}")

      assert json_response(conn, 403)
    end
  end

  # -- Helpers --

  defp create_user(email, handle) do
    {:ok, account} =
      %Account{}
      |> Account.changeset(%{
        handle: "#{handle}-#{System.unique_integer([:positive])}",
        type: "user"
      })
      |> Repo.insert()

    {:ok, user} =
      %User{account_id: account.id}
      |> User.changeset(%{email: email})
      |> Repo.insert()

    %{user | account: account}
  end

  defp authenticate(conn, user) do
    # Use Boruta's client changeset to properly create a client with required keys
    {:ok, client} =
      Boruta.Ecto.Client.create_changeset(%Boruta.Ecto.Client{}, %{
        name: "test-client-#{System.unique_integer([:positive])}",
        redirect_uris: ["http://localhost"],
        access_token_ttl: 3600,
        authorization_code_ttl: 60
      })
      |> Repo.insert()

    # Use Boruta's token changeset to create a valid access token
    {:ok, token} =
      Boruta.Ecto.Token.changeset(%Boruta.Ecto.Token{}, %{
        client_id: client.id,
        sub: to_string(user.id),
        scope: "",
        access_token_ttl: 3600
      })
      |> Repo.insert()

    conn
    |> put_req_header("authorization", "Bearer #{token.value}")
    |> put_req_header("content-type", "application/json")
  end
end
