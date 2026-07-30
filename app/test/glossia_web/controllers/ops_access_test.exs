defmodule GlossiaWeb.OpsAccessTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Accounts
  alias Glossia.TestHelpers

  test "redirects anonymous visitors to sign in", %{conn: conn} do
    conn = get(conn, "/ops")

    assert redirected_to(conn) == "/auth/login"
  end

  test "rejects signed-in users without the instance role", %{conn: conn} do
    user = TestHelpers.create_user("ops-member@test.com", "ops-member")

    conn =
      conn
      |> init_test_session(%{user_id: user.id})
      |> get("/ops")

    assert response(conn, 403) =~ "Operations access requires the super administrator role"
  end

  test "allows users with the super administrator role", %{conn: conn} do
    user = TestHelpers.create_user("ops-admin@test.com", "ops-admin")
    assert {:ok, _user} = Accounts.set_super_admin(user.id)

    conn =
      conn
      |> init_test_session(%{user_id: user.id})
      |> get("/ops")

    assert redirected_to(conn) == "/ops/dashboard"
  end
end
