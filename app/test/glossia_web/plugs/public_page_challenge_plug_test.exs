defmodule GlossiaWeb.Plugs.PublicPageChallengePlugTest do
  use GlossiaWeb.ConnCase, async: false

  alias GlossiaWeb.Plugs.PublicPageChallengePlug

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

  defp with_session(conn, session \\ %{}) do
    conn
    |> Plug.Test.init_test_session(session)
  end

  describe "call/2 — challenge not required" do
    test "passes through when config is disabled", %{conn: conn} do
      disable_challenge!()
      conn = conn |> with_session() |> PublicPageChallengePlug.call([])

      refute conn.halted
      assert conn.status == nil
    end
  end

  describe "call/2 — authenticated" do
    test "passes signed-in visitors even when challenge is enabled", %{conn: conn} do
      enable_challenge!()
      conn = conn |> with_session(%{"user_id" => 42}) |> PublicPageChallengePlug.call([])

      refute conn.halted
      assert conn.status == nil
    end
  end

  describe "call/2 — freshness" do
    test "passes visitors with a fresh verified_at inside the window", %{conn: conn} do
      enable_challenge!(freshness_seconds: 60)
      now = System.system_time(:second)

      conn =
        conn
        |> with_session(%{"public_page_challenge_verified_at" => now - 30})
        |> PublicPageChallengePlug.call([])

      refute conn.halted
    end

    test "redirects when the verified_at timestamp is older than the freshness window",
         %{conn: conn} do
      enable_challenge!(freshness_seconds: 60)
      now = System.system_time(:second)

      conn =
        conn
        |> with_session(%{"public_page_challenge_verified_at" => now - 61})
        |> Map.put(:request_path, "/omarchy/omarchy-site")
        |> PublicPageChallengePlug.call([])

      assert conn.halted
      assert redirected_to(conn) == "/turnstile-challenge"
      assert get_session(conn, "public_page_return_to") == "/omarchy/omarchy-site"
    end
  end

  describe "call/2 — redirect to challenge" do
    test "captures request_path + query into the return_to session key", %{conn: conn} do
      enable_challenge!()

      conn =
        conn
        |> with_session()
        |> Map.put(:request_path, "/omarchy/omarchy-site/-/translations")
        |> Map.put(:query_string, "sort=inserted_at")
        |> PublicPageChallengePlug.call([])

      assert conn.halted
      assert redirected_to(conn) == "/turnstile-challenge"

      assert get_session(conn, "public_page_return_to") ==
               "/omarchy/omarchy-site/-/translations?sort=inserted_at"
    end

    test "captures bare request_path when no query string is present", %{conn: conn} do
      enable_challenge!()

      conn =
        conn
        |> with_session()
        |> Map.put(:request_path, "/omarchy")
        |> Map.put(:query_string, "")
        |> PublicPageChallengePlug.call([])

      assert conn.halted
      assert get_session(conn, "public_page_return_to") == "/omarchy"
    end
  end

  describe "verified_within_freshness?/1" do
    test "true for a fresh integer timestamp inside the window" do
      enable_challenge!(freshness_seconds: 60)
      now = System.system_time(:second)

      assert PublicPageChallengePlug.verified_within_freshness?(%{
               "public_page_challenge_verified_at" => now - 10
             })
    end

    test "false for a nil, missing, or non-integer timestamp" do
      enable_challenge!(freshness_seconds: 60)

      refute PublicPageChallengePlug.verified_within_freshness?(%{})

      refute PublicPageChallengePlug.verified_within_freshness?(%{
               "public_page_challenge_verified_at" => nil
             })

      refute PublicPageChallengePlug.verified_within_freshness?(%{
               "public_page_challenge_verified_at" => "not-a-number"
             })
    end

    test "false for a timestamp past the freshness window" do
      enable_challenge!(freshness_seconds: 60)
      now = System.system_time(:second)

      refute PublicPageChallengePlug.verified_within_freshness?(%{
               "public_page_challenge_verified_at" => now - 61
             })
    end
  end
end
