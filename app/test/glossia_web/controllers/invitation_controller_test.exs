defmodule GlossiaWeb.InvitationControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Accounts
  alias Glossia.Accounts.{Account, User}
  alias Glossia.Repo

  setup do
    Mimic.stub(Glossia.Mailer, :deliver, fn _email -> {:ok, %{}} end)

    admin = create_user("admin@test.com", "ctrlorgadmin")

    {:ok, %{account: account}} =
      Accounts.create_organization(admin, %{
        handle: "ctrlorg-#{System.unique_integer([:positive])}",
        name: "Ctrl Org"
      })

    org = Accounts.get_organization_for_account(account)

    {:ok, invitation} =
      Accounts.create_invitation(org, admin, %{"email" => "invited@test.com", "role" => "member"})

    %{org: org, account: account, admin: admin, invitation: invitation}
  end

  describe "GET /invitations/:token (show)" do
    test "redirects unauthenticated user to login", %{conn: conn, invitation: invitation} do
      conn = get(conn, "/invitations/#{invitation.token}")
      assert redirected_to(conn) == "/auth/login"
      assert get_session(conn, :return_to) == "/invitations/#{invitation.token}"
    end

    test "renders invitation page for authenticated user", %{conn: conn, invitation: invitation} do
      user = create_user("viewer@test.com", "viewer")

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get("/invitations/#{invitation.token}")

      assert html_response(conn, 200) =~ "Ctrl Org"
    end

    test "redirects with error for invalid token", %{conn: conn} do
      user = create_user("viewer2@test.com", "viewer2")

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get("/invitations/badtoken")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not valid"
    end

    test "redirects with info for already accepted invitation", %{
      conn: conn,
      invitation: invitation
    } do
      acceptor = create_user("acceptor@test.com", "acceptor")
      Accounts.accept_invitation(invitation, acceptor)

      conn =
        conn
        |> init_test_session(%{user_id: acceptor.id})
        |> get("/invitations/#{invitation.token}")

      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /invitations/:token/accept" do
    test "accepts invitation and redirects to org", %{
      conn: conn,
      invitation: invitation,
      account: account
    } do
      acceptor = create_user("accept2@test.com", "accept2")

      conn =
        conn
        |> init_test_session(%{user_id: acceptor.id})
        |> post("/invitations/#{invitation.token}/accept")

      assert redirected_to(conn) == "/#{account.handle}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "joined"
    end

    test "redirects unauthenticated user to login", %{conn: conn, invitation: invitation} do
      conn = post(conn, "/invitations/#{invitation.token}/accept")
      assert redirected_to(conn) == "/auth/login"
    end
  end

  describe "POST /invitations/:token/decline" do
    test "declines invitation and redirects", %{conn: conn, invitation: invitation} do
      conn = post(conn, "/invitations/#{invitation.token}/decline")
      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "declined"
    end

    test "redirects with error for invalid token", %{conn: conn} do
      conn = post(conn, "/invitations/badtoken/decline")
      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not valid"
    end
  end

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
end
