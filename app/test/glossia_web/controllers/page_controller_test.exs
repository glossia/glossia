defmodule GlossiaWeb.PageControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.TestHelpers

  test "GET / renders the public homepage for guests", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Open source language OS"
    assert response =~ "https://community.glossia.ai"
    assert response =~ "Visit the forum"
    refute response =~ "discord.gg"
  end

  test "GET /es does not loop for an account whose handle reads as a locale", %{conn: conn} do
    # Handles like this predate the locale prefixes; the marketing page now
    # owns the URL, and redirecting to it from itself would loop forever.
    user = TestHelpers.create_user("locale-handle@test.com", "localehandle")
    {:ok, _account} = force_handle(user, "es")

    conn =
      conn
      |> init_test_session(%{user_id: user.id})
      |> get("/es")

    assert html_response(conn, 200)
  end

  test "GET / redirects authenticated users to their account", %{conn: conn} do
    user = TestHelpers.create_user("page-root-access@test.com", "pageroot")

    conn =
      conn
      |> init_test_session(%{user_id: user.id})
      |> get(~p"/")

    assert redirected_to(conn) == "/#{user.account.handle}"
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
    assert response(conn, 200) =~ "This tutorial connects a GitHub repository to Glossia"
  end

  test "GET /sitemap.xml exposes the sitemap", %{conn: conn} do
    conn = get(conn, ~p"/sitemap.xml")
    assert response(conn, 200) =~ "<urlset"
  end

  test "GET /robots.txt points crawlers to the sitemap", %{conn: conn} do
    sitemap_url = GlossiaWeb.Endpoint.url() |> URI.merge("/sitemap.xml") |> URI.to_string()

    conn = get(conn, ~p"/robots.txt")

    assert response(conn, 200) == "User-agent: *\nAllow: /\nSitemap: #{sitemap_url}\n"
  end

  test "GET /llms.txt gives agents an index of public documentation", %{conn: conn} do
    conn = get(conn, ~p"/llms.txt")
    response = response(conn, 200)

    assert response =~ "# Glossia"
    assert response =~ "## Documentation"
    assert response =~ "Getting started"
  end

  test "documentation pages expose complete social metadata and structured data", %{conn: conn} do
    canonical_url =
      GlossiaWeb.Endpoint.url()
      |> URI.merge("/docs/tutorials/getting-started")
      |> URI.to_string()

    conn = get(conn, ~p"/docs/tutorials/getting-started")
    response = html_response(conn, 200)

    assert response =~ ~s(property="og:url" content="#{canonical_url}")
    assert response =~ ~s(property="og:type" content="website")
    assert response =~ ~s(name="twitter:card" content="summary_large_image")
    assert response =~ ~s(type="application/ld+json")
    assert response =~ ~s("@type":"WebPage")
  end

  # `es` is reserved now, so the collision can only be created the way it
  # happened in production: straight in the database.
  defp force_handle(user, handle) do
    user.account
    |> Ecto.Changeset.change(handle: handle)
    |> Glossia.Repo.update()
  end
end
