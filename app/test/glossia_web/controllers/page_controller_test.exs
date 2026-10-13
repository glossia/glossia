defmodule GlossiaWeb.PageControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.{Docs, I18n, TestHelpers}

  test "GET / renders the public homepage for guests", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Language OS"
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

    body = response(conn, 200)
    assert body =~ "User-agent: *\nDisallow: /\n"
    assert body =~ "Allow: /$\n"
    assert body =~ "Allow: /docs/tutorials/getting-started$\n"
    assert body =~ "Allow: /docs/tutorials/getting-started.md$\n"
    assert body =~ "Allow: /es/docs/tutorials/getting-started$\n"
    assert body =~ "Sitemap: #{sitemap_url}\n"
    refute body =~ "Allow: /api"
    refute body =~ "Allow: /auth"
    refute body =~ "Allow: /*"
  end

  test "robots allow rendering assets and public previews without exposing application routes", %{
    conn: conn
  } do
    body = conn |> get(~p"/robots.txt") |> response(200)

    for path <- [
          ~p"/assets/styles.css",
          ~p"/assets/noora.css",
          ~p"/assets/js/app.js",
          ~p"/assets/logos/glossia.svg",
          ~p"/fonts/inter.woff2",
          ~p"/images/logo-rounded.png",
          ~p"/images/logo-squared.jpg",
          ~p"/favicon.ico",
          ~p"/og/marketing/blog/example"
        ] do
      assert robots_allowed?(body, path), "rendering resource blocked: #{path}"
    end

    for path <- [
          ~p"/auth/login",
          ~p"/api/openapi.json",
          "/acme",
          "/acme/project",
          "/acme/project/-/translations",
          "/og/app/acme/example",
          "/og/app/acme/project/example",
          "/assets-lookalike/project",
          "/favicon.ico/project"
        ] do
      refute robots_allowed?(body, path), "application route allowed: #{path}"
    end

    for locale <- I18n.locales(), path <- [~p"/blog/feed.xml", ~p"/changelog/feed.xml"] do
      assert robots_allowed?(body, I18n.localize_path(locale, path))
    end
  end

  for path <- ["/robots.txt", "/llms.txt", "/llms-full.txt"] do
    test "#{path} stays fetchable and nonindexable for GET, HEAD and revalidation", %{conn: conn} do
      conn = get(conn, unquote(path))
      assert response(conn, 200) != ""
      assert get_resp_header(conn, "x-robots-tag") == ["noindex, follow"]
      [etag] = get_resp_header(conn, "etag")

      cached = conn |> recycle() |> put_req_header("if-none-match", etag) |> get(unquote(path))
      assert response(cached, 304) == ""
      assert get_resp_header(cached, "x-robots-tag") == ["noindex, follow"]
      assert get_resp_header(cached, "etag") == [etag]

      head = conn |> recycle() |> head(unquote(path))
      assert response(head, 200) == ""
      assert get_resp_header(head, "x-robots-tag") == ["noindex, follow"]

      robots = conn |> recycle() |> get(~p"/robots.txt") |> response(200)
      assert robots_allowed?(robots, unquote(path))
    end
  end

  test "GET /llms.txt gives agents an index of public documentation", %{conn: conn} do
    conn = get(conn, ~p"/llms.txt")
    response = response(conn, 200)

    assert response =~ "# Glossia"
    assert response =~ "## Documentation"
    assert response =~ "Getting started"
  end

  test "GET /llms-full.txt exports documentation without the website chrome", %{conn: conn} do
    conn = get(conn, ~p"/llms-full.txt")
    body = response(conn, 200)
    assert body =~ "# Glossia documentation"
    assert body =~ "# Why Glossia"
    assert body =~ "# Glossia vs Weblate"

    for page <- Docs.all_pages() do
      source = GlossiaWeb.Endpoint.url() |> URI.merge(Docs.path_for(page)) |> URI.to_string()
      assert body =~ "Source: #{source}\n", "missing documentation: #{page.id}"
    end

    assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
    refute String.starts_with?(body, "<!DOCTYPE")
    assert get_resp_header(conn, "etag") != []
  end

  test "published HTML is indexable but authentication pages are not", %{conn: conn} do
    marketing = get(conn, ~p"/docs/explanation/why-glossia")
    assert get_resp_header(marketing, "x-robots-tag") == ["index, follow"]
    auth = get(recycle(marketing), ~p"/auth/login")
    assert get_resp_header(auth, "x-robots-tag") == ["noindex, nofollow"]
  end

  test "sitemap contains comparisons and no fragment URLs", %{conn: conn} do
    body = conn |> get(~p"/sitemap.xml") |> response(200)
    assert body =~ "/docs/explanation/glossia-vs-crowdin</loc>"
    refute body =~ "/changelog#"
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

  # The generated policy uses literal prefixes and exact `$` rules. Evaluate
  # their longest-match semantics instead of merely asserting lines exist.
  defp robots_allowed?(body, path) do
    body
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case String.split(line, ": ", parts: 2) do
        [action, pattern] when action in ["Allow", "Disallow"] ->
          prefix = String.trim_trailing(pattern, "$")

          matches? =
            if String.ends_with?(pattern, "$"),
              do: path == prefix,
              else: String.starts_with?(path, prefix)

          if matches?, do: [{String.length(prefix), action == "Allow"}], else: []

        _ ->
          []
      end
    end)
    |> Enum.max(fn -> {0, true} end)
    |> elem(1)
  end

  # `es` is reserved now, so the collision can only be created the way it
  # happened in production: straight in the database.
  defp force_handle(user, handle) do
    user.account
    |> Ecto.Changeset.change(handle: handle)
    |> Glossia.Repo.update()
  end
end
