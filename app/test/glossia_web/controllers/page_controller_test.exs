defmodule GlossiaWeb.PageControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.TestHelpers

  test "GET / renders the public homepage for guests", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "The language OS for your organization"
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

  for path <- ["/blog", "/features", "/changelog", "/docs"] do
    test "GET #{path} is exposed as a public page", %{conn: conn} do
      conn = get(conn, unquote(path))
      assert html_response(conn, 200)
    end
  end

  test "GET /blog/feed.xml exposes the blog feed", %{conn: conn} do
    conn = get(conn, ~p"/blog/feed.xml")
    assert response(conn, 200) =~ "<rss version=\"2.0\">"
  end

  test "GET /docs/search.json exposes the docs search index", %{conn: conn} do
    conn = get(conn, ~p"/docs/search.json")

    assert Enum.any?(json_response(conn, 200), &(&1["title"] == "Getting started"))
  end

  test "GET /docs/:category/:slug.md exposes raw markdown", %{conn: conn} do
    conn = get(conn, "/docs/tutorials/getting-started.md")
    assert response(conn, 200) =~ "This tutorial walks you through installing Glossia"
  end

  test "GET /sitemap.xml exposes the sitemap", %{conn: conn} do
    conn = get(conn, ~p"/sitemap.xml")
    assert response(conn, 200) =~ "<urlset"
  end
end
