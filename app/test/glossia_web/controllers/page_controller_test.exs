defmodule GlossiaWeb.PageControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.TestHelpers

  test "GET / redirects guests to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == "/auth/login"
  end

  test "GET / redirects users with access to their account", %{conn: conn} do
    user = TestHelpers.create_user("page-root-access@test.com", "pageroot")

    conn =
      conn
      |> init_test_session(%{user_id: user.id})
      |> get(~p"/")

    assert redirected_to(conn) == "/#{user.account.handle}"
  end

  test "GET / redirects users without access to the waitlist", %{conn: conn} do
    user = TestHelpers.create_user("page-root-waitlist@test.com", "pagewait", has_access: false)

    conn =
      conn
      |> init_test_session(%{user_id: user.id})
      |> get(~p"/")

    assert redirected_to(conn) == "/interest"
  end

  for path <- [
        "/blog",
        "/blog/feed.xml",
        "/features",
        "/changelog",
        "/changelog/feed.xml",
        "/docs",
        "/docs/search.json",
        "/sitemap.xml"
      ] do
    test "GET #{path} is no longer exposed", %{conn: conn} do
      conn = get(conn, unquote(path))
      assert response(conn, 404)
    end
  end
end
