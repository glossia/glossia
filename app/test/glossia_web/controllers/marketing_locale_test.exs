defmodule GlossiaWeb.MarketingLocaleTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.TestHelpers
  alias GlossiaWeb.Plugs.Locale

  describe "language negotiation on unprefixed URLs" do
    test "sends a Spanish browser to the Spanish page", %{conn: conn} do
      conn =
        conn
        |> browser_request("es-ES,es;q=0.9,en;q=0.5")
        |> get(~p"/blog")

      assert redirected_to(conn) == "/es/blog"
    end

    test "keeps the query string when redirecting", %{conn: conn} do
      conn =
        conn
        |> browser_request("ja")
        |> get(~p"/blog?ref=newsletter")

      assert redirected_to(conn) == "/ja/blog?ref=newsletter"
    end

    test "serves English when the browser asks for a language we do not have", %{conn: conn} do
      conn =
        conn
        |> browser_request("sv-SE,sv;q=0.9")
        |> get(~p"/blog")

      assert html_response(conn, 200)
    end

    test "never redirects a crawler", %{conn: conn} do
      conn =
        conn
        |> browser_request("es-ES,es;q=0.9")
        |> put_req_header(
          "user-agent",
          "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
        )
        |> get(~p"/blog")

      assert html_response(conn, 200)
    end

    test "honours an explicit choice over the browser's language", %{conn: conn} do
      conn =
        conn
        |> browser_request("es-ES,es;q=0.9")
        |> put_req_cookie(Locale.cookie(), "en")
        |> get(~p"/blog")

      assert html_response(conn, 200)
    end

    test "honours the account language of a signed-in user", %{conn: conn} do
      user = TestHelpers.create_user("locale-preference@test.com", "localepreference")
      {:ok, user} = Glossia.Accounts.update_user_locale(user, "de")

      conn =
        conn
        |> browser_request("es-ES,es;q=0.9")
        |> init_test_session(%{user_id: user.id})
        |> get(~p"/blog")

      assert redirected_to(conn) == "/de/blog"
    end

    test "tell caches the response depends on the visitor", %{conn: conn} do
      conn = conn |> browser_request("en") |> get(~p"/blog")

      assert get_resp_header(conn, "vary") == ["accept-language, cookie"]
    end

    test "leaves non-HTML requests alone", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept-language", "es-ES,es;q=0.9")
        |> get(~p"/blog/feed.xml")

      assert response(conn, 200) =~ "<rss"
    end
  end

  describe "prefixed URLs" do
    test "serve the translated page without redirecting", %{conn: conn} do
      conn = get(conn, "/es/blog")
      response = html_response(conn, 200)

      assert response =~ ~s(<html lang="es")
      # The navigation itself comes from Gettext rather than from content.
      assert response =~ "Características"
    end

    test "serve translated content", %{conn: conn} do
      post = Glossia.Blog.all_posts("es") |> List.first()

      conn = get(conn, "/es/blog/#{post.slug}")

      assert html_response(conn, 200) =~ post.title
    end

    test "serve translated docs, features and legal pages", %{conn: conn} do
      page = Glossia.Docs.all_pages("es") |> Enum.find(&(&1.category == "how-to"))
      assert html_response(get(conn, "/es" <> Glossia.Docs.path_for(page)), 200) =~ page.title

      feature = Glossia.Features.all_pages("es") |> List.first()
      assert html_response(get(conn, "/es/features/#{feature.slug}"), 200) =~ feature.title

      terms = Glossia.Legal.latest_version!("terms", "es")
      assert html_response(get(conn, "/es/terms"), 200) =~ terms.title
    end

    test "win over the browser's language", %{conn: conn} do
      conn =
        conn
        |> browser_request("ja")
        |> get("/es/blog")

      assert html_response(conn, 200) =~ ~s(<html lang="es")
    end

    test "point search engines at themselves as the canonical URL", %{conn: conn} do
      response = conn |> get("/es/blog") |> html_response(200)
      canonical_url = GlossiaWeb.Endpoint.url() |> URI.merge("/es/blog") |> URI.to_string()

      assert response =~ ~s(rel="canonical" href="#{canonical_url}")
    end

    test "do not vary, since the URL alone decides the language", %{conn: conn} do
      conn = get(conn, "/es/blog")

      assert get_resp_header(conn, "vary") == []
    end

    test "advertise their translations through hreflang", %{conn: conn} do
      response = conn |> get("/es/blog") |> html_response(200)

      assert response =~ ~s(rel="alternate" hreflang="es")
      assert response =~ ~s(rel="alternate" hreflang="pt-BR")
      assert response =~ ~s(hreflang="x-default")
    end

    test "are not confused with account handles", %{conn: _conn} do
      assert Glossia.Accounts.ReservedHandles.reserved?("es")
      assert Glossia.Accounts.ReservedHandles.reserved?("zh-hans")
    end
  end

  describe "GET /-/locale/:locale" do
    test "remembers the choice and returns to the translated page", %{conn: conn} do
      conn = get(conn, ~p"/-/locale/es?#{[return_to: "/blog"]}")

      assert redirected_to(conn) == "/es/blog"
      assert conn.resp_cookies[Locale.cookie()].value == "es"
    end

    test "switches between two translations of the same page", %{conn: conn} do
      conn = get(conn, ~p"/-/locale/ja?#{[return_to: "/es/docs"]}")

      assert redirected_to(conn) == "/ja/docs"
    end

    test "returns to the same page when it has no translated URL", %{conn: conn} do
      conn = get(conn, ~p"/-/locale/es?#{[return_to: "/signup"]}")

      assert redirected_to(conn) == "/signup"
    end

    test "drops the prefix when switching back to English", %{conn: conn} do
      conn = get(conn, ~p"/-/locale/en?#{[return_to: "/es/blog"]}")

      assert redirected_to(conn) == "/blog"
      assert conn.resp_cookies[Locale.cookie()].value == "en"
    end

    test "refuses to redirect off-site", %{conn: conn} do
      conn = get(conn, ~p"/-/locale/es?#{[return_to: "//evil.example.com"]}")

      assert redirected_to(conn) == "/es"
    end

    test "keeps the query string of the page it returns to", %{conn: conn} do
      conn = get(conn, ~p"/-/locale/de?#{[return_to: "/es/blog?ref=newsletter"]}")

      assert redirected_to(conn) == "/de/blog?ref=newsletter"
    end

    test "404s on a language we do not serve", %{conn: conn} do
      conn = get(conn, ~p"/-/locale/sv?#{[return_to: "/blog"]}")

      assert conn.status == 404
    end

    test "stores the choice on the account of a signed-in user", %{conn: conn} do
      user = TestHelpers.create_user("locale-switch@test.com", "localeswitch")

      conn
      |> init_test_session(%{user_id: user.id})
      |> put_req_header("sec-fetch-site", "same-origin")
      |> get(~p"/-/locale/fr?#{[return_to: "/blog"]}")

      assert Glossia.Accounts.get_user(user.id).locale == "fr"
    end

    test "accepts a browser too old for sec-fetch-site when the referrer is ours", %{conn: conn} do
      user = TestHelpers.create_user("locale-referer@test.com", "localereferer")

      conn
      |> init_test_session(%{user_id: user.id})
      |> put_req_header("referer", GlossiaWeb.Endpoint.url() <> "/blog")
      |> get(~p"/-/locale/ko?#{[return_to: "/blog"]}")

      assert Glossia.Accounts.get_user(user.id).locale == "ko"
    end

    test "refuses an account write from a foreign referrer", %{conn: conn} do
      user = TestHelpers.create_user("locale-foreign@test.com", "localeforeign")

      conn
      |> init_test_session(%{user_id: user.id})
      |> put_req_header("referer", "https://evil.example.com/page")
      |> get(~p"/-/locale/ko?#{[return_to: "/blog"]}")

      assert is_nil(Glossia.Accounts.get_user(user.id).locale)
    end

    test "refuses to rewrite an account from a cross-site request", %{conn: conn} do
      user = TestHelpers.create_user("locale-crosssite@test.com", "localecrosssite")

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> put_req_header("sec-fetch-site", "cross-site")
        |> get(~p"/-/locale/fr?#{[return_to: "/blog"]}")

      assert redirected_to(conn) == "/fr/blog"
      assert is_nil(Glossia.Accounts.get_user(user.id).locale)
    end

    test "sends a crafted return_to home instead of crashing", %{conn: conn} do
      for return_to <- ["/\\evil.example.com", "/%09evil", "/\tevil"] do
        conn = get(conn, ~p"/-/locale/es?#{[return_to: return_to]}")

        assert redirected_to(conn) == "/es"
      end
    end
  end

  describe "sitemap" do
    test "lists every locale with its alternates", %{conn: conn} do
      body = conn |> get(~p"/sitemap.xml") |> response(200)

      assert body =~ "/es/blog</loc>"
      assert body =~ "/zh-hans/docs</loc>"
      assert body =~ ~s(<xhtml:link rel="alternate" hreflang="x-default")
    end
  end

  defp browser_request(conn, accept_language) do
    conn
    |> put_req_header("accept-language", accept_language)
    |> put_req_header("accept", "text/html,application/xhtml+xml")
    |> put_req_header("user-agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/605")
  end
end
