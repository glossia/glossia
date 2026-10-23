defmodule GlossiaWeb.Plugs.SiteMarkdownTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias Glossia.{Blog, Docs, Features, I18n, PublicContent}
  alias GlossiaWeb.Plugs.{NoIndex, SiteMarkdown}

  test "serves every published page and locale without a session or controller" do
    for locale <- I18n.locales(), {path, markdown} <- PublicContent.documents(locale) do
      path = I18n.localize_path(locale, path)
      conn = :get |> conn(PublicContent.markdown_path(path)) |> SiteMarkdown.call([])
      assert conn.halted
      assert conn.status == 200
      assert conn.resp_body == markdown
      assert get_resp_header(conn, "content-type") == ["text/markdown; charset=utf-8"]

      assert get_resp_header(conn, "cache-control") == [
               "public, max-age=300, stale-while-revalidate=60"
             ]

      assert get_resp_header(conn, "link") |> hd() =~ "rel=\"canonical\""
      assert get_resp_header(conn, "set-cookie") == []
      refute Map.has_key?(conn.assigns, :current_user)
    end
  end

  test "the prebuilt inventory includes every current documentation page" do
    for locale <- I18n.locales(), page <- Docs.all_pages(locale) do
      assert Map.has_key?(PublicContent.documents(locale), Docs.path_for(page))
    end
  end

  test "Markdown-only comparisons use their Markdown URL as the canonical URL" do
    for locale <- I18n.locales(), page <- Docs.markdown_only_pages(locale) do
      path = I18n.localize_path(locale, Docs.path_for(page))
      markdown_path = PublicContent.markdown_path(path)
      canonical = GlossiaWeb.Endpoint.url() |> URI.merge(markdown_path) |> URI.to_string()
      explicit = conn(:get, markdown_path) |> SiteMarkdown.call([])

      negotiated =
        conn(:get, path) |> put_req_header("accept", "text/markdown") |> SiteMarkdown.call([])

      assert explicit.status == 200
      assert explicit.resp_body =~ page.raw_markdown
      assert negotiated.resp_body == explicit.resp_body
      assert hd(get_resp_header(explicit, "link")) =~ ~s(<#{canonical}>; rel="canonical")
      refute (conn(:get, path) |> SiteMarkdown.call([])).halted
    end
  end

  test "negotiates Markdown before browser language redirects" do
    conn =
      conn(:get, "/docs/tutorials/getting-started")
      |> put_req_header("accept", "text/markdown")
      |> put_req_header("accept-language", "es")
      |> SiteMarkdown.call([])

    assert conn.status == 200
    assert conn.resp_body =~ "This tutorial connects a GitHub repository"
    assert get_resp_header(conn, "vary") == ["Accept"]
    assert get_resp_header(conn, "location") == []
  end

  test "retains authored source rather than rendering HTML back into Markdown" do
    post = hd(Blog.all_posts())
    feature = hd(Features.all_pages())
    assert PublicContent.get("/blog/#{post.slug}") =~ post.raw_markdown
    assert PublicContent.get("/features/#{feature.slug}") =~ feature.raw_markdown
  end

  test "honors Accept quality and exact media types" do
    for accept <- [
          "*/*",
          "text/html",
          "text/markdown;q=0",
          "text/markdown-other",
          "text/markdown;q=0.2, text/html;q=0.9",
          "text/markdown;q=invalid"
        ] do
      conn = conn(:get, "/docs") |> put_req_header("accept", accept) |> SiteMarkdown.call([])
      refute conn.halted
    end

    for accept <- [
          "text/markdown; charset=utf-8",
          "text/markdown;q=0.9, text/html;q=0.2",
          "TEXT/MARKDOWN"
        ] do
      conn = conn(:get, "/docs") |> put_req_header("accept", accept) |> SiteMarkdown.call([])
      assert conn.halted
      assert conn.status == 200
    end
  end

  test "preserves Vary and advertises Markdown on HTML responses" do
    conn =
      conn(:get, "/docs")
      |> SiteMarkdown.call([])
      |> put_resp_header("vary", "accept-language, cookie")
      |> send_resp(200, "HTML")

    assert get_resp_header(conn, "vary") == ["accept-language, cookie, Accept"]
    assert get_resp_header(conn, "link") |> hd() =~ "</docs.md>"
  end

  test "supports conditional requests, including weak and multiple validators" do
    first = conn(:get, "/docs.md") |> SiteMarkdown.call([])
    [etag] = get_resp_header(first, "etag")

    for validator <- [etag, "W/#{etag}", "\"unrelated\", #{etag}", "*"] do
      cached =
        conn(:get, "/docs.md")
        |> put_req_header("if-none-match", validator)
        |> SiteMarkdown.call([])

      assert cached.status == 304
      assert cached.resp_body == ""
      assert get_resp_header(cached, "etag") == [etag]
    end

    fresh =
      conn(:get, "/docs.md")
      |> put_req_header("if-none-match", "\"unrelated\"")
      |> SiteMarkdown.call([])

    assert fresh.status == 200
  end

  test "HEAD carries the GET headers without a response body" do
    get = conn(:get, "/docs.md") |> SiteMarkdown.call([])
    head = conn(:head, "/docs.md") |> Plug.Head.call([]) |> SiteMarkdown.call([])
    assert head.status == 200
    assert head.resp_body == ""
    assert get_resp_header(head, "etag") == get_resp_header(get, "etag")
    assert get_resp_header(head, "content-type") == get_resp_header(get, "content-type")
  end

  test "never handles unknown, application or mutation requests" do
    for path <- [
          "/acme",
          "/acme/project",
          "/acme/project.md",
          "/acme/docs/builds",
          "/api/openapi.json",
          "/auth/login",
          "/docs/explanation/missing.md",
          "/zz/docs.md",
          "/en/docs.md",
          "/ES/docs.md",
          "/index"
        ] do
      conn =
        conn(:get, path) |> put_req_header("accept", "text/markdown") |> SiteMarkdown.call([])

      refute conn.halted
    end

    conn = conn(:post, "/docs.md") |> SiteMarkdown.call([])
    refute conn.halted
  end

  test "default noindex does not override published content but covers errors" do
    conn = conn(:get, "/docs.md") |> NoIndex.call(only_if_unset: true) |> SiteMarkdown.call([])
    assert get_resp_header(conn, "x-robots-tag") == ["index, follow"]

    error =
      conn(:get, "/docs")
      |> NoIndex.call(only_if_unset: true)
      |> SiteMarkdown.call([])
      |> send_resp(404, "missing")

    assert get_resp_header(error, "x-robots-tag") == ["noindex, nofollow"]

    private =
      conn(:get, "/acme")
      |> NoIndex.call(only_if_unset: true)
      |> SiteMarkdown.call([])
      |> send_resp(200, "dashboard")

    assert get_resp_header(private, "x-robots-tag") == ["noindex, nofollow"]
  end
end
