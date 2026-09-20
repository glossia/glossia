defmodule GlossiaWeb.PublicPageChallengeControllerTest do
  use GlossiaWeb.ConnCase, async: false

  @app :glossia
  @config_key Glossia.Cloudflare.Turnstile.PublicPage

  setup do
    original = Application.get_env(@app, @config_key, [])

    on_exit(fn ->
      Application.put_env(@app, @config_key, original)
    end)

    :ok
  end

  defp enable_challenge!(overrides \\ []) do
    Application.put_env(
      @app,
      @config_key,
      Keyword.merge(
        [enabled?: true, site_key: "test-site", secret_key: "test-secret", freshness_seconds: 60],
        overrides
      )
    )
  end

  defp disable_challenge! do
    Application.put_env(@app, @config_key, enabled?: false)
  end

  describe "GET /turnstile-challenge" do
    test "redirects to captured return path when the challenge is disabled", %{conn: conn} do
      disable_challenge!()

      conn =
        conn
        |> Plug.Test.init_test_session(%{"public_page_return_to" => "/omarchy"})
        |> get("/turnstile-challenge")

      assert redirected_to(conn) == "/omarchy"
      assert get_resp_header(conn, "cache-control") |> List.first() =~ "no-store"
    end

    test "redirects to `/` when the challenge is disabled and no return path was stashed",
         %{conn: conn} do
      disable_challenge!()
      conn = conn |> Plug.Test.init_test_session(%{}) |> get("/turnstile-challenge")
      assert redirected_to(conn) == "/"
    end

    test "redirects signed-in visitors past the challenge", %{conn: conn} do
      enable_challenge!()

      user =
        Glossia.TestHelpers.create_user("challenge-signed-in@test.com", "challenge-signed-in")

      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "user_id" => user.id,
          "public_page_return_to" => "/omarchy/omarchy-site"
        })
        |> get("/turnstile-challenge")

      assert redirected_to(conn) == "/omarchy/omarchy-site"
    end

    test "redirects visitors with a fresh verified_at past the challenge", %{conn: conn} do
      enable_challenge!(freshness_seconds: 60)
      now = System.system_time(:second)

      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "public_page_challenge_verified_at" => now - 10,
          "public_page_return_to" => "/omarchy"
        })
        |> get("/turnstile-challenge")

      assert redirected_to(conn) == "/omarchy"
    end

    test "renders the widget page for anonymous, unverified visitors when required",
         %{conn: conn} do
      enable_challenge!()

      conn = conn |> Plug.Test.init_test_session(%{}) |> get("/turnstile-challenge")

      assert html_response(conn, 200) =~ ~r/turnstile-widget/
      assert html_response(conn, 200) =~ "test-site"
    end

    test "captures ?return_to= from the query string into the session, if local", %{conn: conn} do
      enable_challenge!()

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> get("/turnstile-challenge?return_to=%2Fomarchy%2Fomarchy-site")

      assert get_session(conn, "public_page_return_to") == "/omarchy/omarchy-site"
    end

    test "ignores a non-local ?return_to=", %{conn: conn} do
      enable_challenge!()

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> get("/turnstile-challenge?return_to=https%3A%2F%2Fevil.example%2Fomarchy")

      assert get_session(conn, "public_page_return_to") == nil
    end

    test "ignores a protocol-relative ?return_to=", %{conn: conn} do
      enable_challenge!()

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> get("/turnstile-challenge?return_to=%2F%2Fevil.example%2Fomarchy")

      assert get_session(conn, "public_page_return_to") == nil
    end
  end

  describe "POST /turnstile-challenge/verify — rate limit" do
    test "returns 429 with the challenge page after burning the per-IP bucket", %{conn: conn} do
      enable_challenge!()

      # Burn well past the 30/minute per-IP verify bucket. Each request is
      # rejected inside `check_rate_limit/1` before it reaches Turnstile,
      # so no HTTP round-trip is issued.
      Enum.each(1..31, fn _ ->
        conn
        |> Plug.Test.init_test_session(%{})
        |> post("/turnstile-challenge/verify", %{"cf-turnstile-response" => "x"})
      end)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> post("/turnstile-challenge/verify", %{"cf-turnstile-response" => "x"})

      assert conn.status == 429
    end
  end
end
