defmodule GlossiaWeb.AuthControllerTest do
  use GlossiaWeb.ConnCase, async: false

  use Mimic
  import Swoosh.TestAssertions

  setup %{conn: conn} do
    previous_providers = Application.get_env(:glossia, :oauth_providers, [])

    on_exit(fn ->
      Application.put_env(:glossia, :oauth_providers, previous_providers)
    end)

    unique = System.unique_integer([:positive])
    {:ok, conn: %{conn | remote_ip: {10, 1, rem(div(unique, 256), 256), rem(unique, 256)}}}
  end

  describe "GET /auth/login" do
    test "only renders configured sign-in providers", %{conn: conn} do
      Application.put_env(:glossia, :oauth_providers,
        github: [client_id: "github-id", client_secret: "github-secret"]
      )

      conn = get(conn, ~p"/auth/login")
      response = html_response(conn, 200)

      assert response =~ "Continue with GitHub"
      refute response =~ "Continue with GitLab"
    end

    test "links to show interest", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")
      response = html_response(conn, 200)

      assert response =~ "Log in to Glossia"
      assert response =~ ~s(href="/signup")
      assert response =~ "Show interest"
      refute response =~ "Join the waitlist"

      if System.get_env("GLOSSIA_EDITION", "core") == "core" do
        refute response =~ "Continue with your organization"
        refute response =~ "organization[email]"
      else
        assert response =~ "Continue with your organization"
      end
    end

    test "redirects when a known provider is not configured", %{conn: conn} do
      Application.put_env(:glossia, :oauth_providers, [])

      conn = get(conn, ~p"/auth/github")

      assert redirected_to(conn) == ~p"/auth/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "That sign-in method is not available."
    end

    test "renders development sign-in as the seeded test user" do
      html =
        %{
          flash: %{},
          dev_routes: true,
          providers: [],
          mode: :login,
          turnstile_required?: false,
          turnstile_site_key: nil,
          csrf_token: "test-csrf",
          title: "Log in to Glossia",
          subtitle: "Welcome back. Choose a sign-in method to continue.",
          switch_prompt: "New to Glossia?",
          switch_href: "/signup",
          switch_label: "Show interest"
        }
        |> GlossiaWeb.AuthHTML.login()
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert html =~ "Sign in as test user"
      refute html =~ "Continue with GitHub"
      refute html =~ "Continue with GitLab"
    end
  end

  describe "GET /signup" do
    test "renders the sign-up entry point", %{conn: conn} do
      conn = get(conn, ~p"/signup")
      response = html_response(conn, 200)

      assert response =~ "Interested in Glossia?"
      assert response =~ "Show interest"
      assert response =~ ~s(name="interest[email]")
      refute response =~ "Continue with GitHub"
      refute response =~ "Continue with GitLab"
      refute response =~ "Sign in as test user"
      assert response =~ ~s(href="/auth/login")
      assert response =~ "Log in"
      refute response =~ "Join the waitlist"
    end
  end

  describe "POST /signup" do
    test "limits repeated interest requests", %{conn: conn} do
      for _ <- 1..5 do
        assert conn |> post(~p"/signup", interest: %{email: "invalid"}) |> html_response(422)
      end

      conn = post(conn, ~p"/signup", interest: %{email: "interested@example.com"})
      assert response(conn, 429) == "Rate limit exceeded"
      assert get_resp_header(conn, "retry-after") != []
      assert_no_email_sent()
    end

    test "emails Pedro without creating a user", %{conn: conn} do
      count = Glossia.Repo.aggregate(Glossia.Accounts.User, :count)
      conn = post(conn, ~p"/signup", interest: %{email: " interested@example.com "})

      assert redirected_to(conn) == ~p"/signup"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Thanks for your interest!"

      assert_email_sent(fn email ->
        assert email.to == [{"", "pedro@glossia.ai"}]
        assert email.reply_to == {"", "interested@example.com"}
        assert email.text_body =~ "interested@example.com"
      end)

      assert Glossia.Repo.aggregate(Glossia.Accounts.User, :count) == count
    end

    test "rejects invalid and missing email addresses", %{conn: conn} do
      for email <- [
            "",
            "invalid",
            "a@b",
            "a@b.com\r\nBcc: other@example.com",
            String.duplicate("a", 255) <> "@example.com"
          ] do
        response = conn |> post(~p"/signup", interest: %{email: email}) |> html_response(422)
        assert response =~ "Interested in Glossia?"
      end

      assert_no_email_sent()
    end

    test "preserves email and reports a delivery failure", %{conn: conn} do
      expect(Glossia.Mailer, :deliver, fn _email -> {:error, :unavailable} end)
      conn = post(conn, ~p"/signup", interest: %{email: "interested@example.com"})
      response = html_response(conn, 503)
      assert response =~ "We couldn’t send your request."
      assert response =~ "interested@example.com"
      refute response =~ "Thanks for your interest!"
    end

    test "requires the configured verification challenge", %{conn: conn} do
      stub(Glossia.Cloudflare.Turnstile, :required?, fn -> true end)
      stub(Glossia.Cloudflare.Turnstile, :site_key, fn -> "test-site-key" end)
      stub(GlossiaWeb.RateLimit.Registration, :hit, fn _ -> {:allow, 1} end)

      expect(Glossia.Cloudflare.Turnstile, :verify, fn "bad-token", opts ->
        assert opts[:expected_action] == "signup"
        {:error, :invalid_token}
      end)

      conn =
        conn
        |> init_test_session(%{"_csrf_token" => "test-session"})
        |> post(~p"/signup", %{
          "interest" => %{"email" => "interested@example.com"},
          "cf-turnstile-response" => "bad-token"
        })

      assert html_response(conn, 200) =~ "The verification challenge did not pass."
      assert_no_email_sent()
    end
  end

  test "old signup gates cannot authorize registration", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{signup_gate_verified_at: System.system_time(:second)})
      |> post(~p"/auth/gate/github")

    assert redirected_to(conn) == ~p"/signup"
    assert get_session(conn, :signup_gate_verified_at) == nil
  end

  describe "provider callback" do
    test "blocks new users even with a previously verified signup session", %{conn: conn} do
      count = Glossia.Repo.aggregate(Glossia.Accounts.User, :count)

      expect(Glossia.Auth, :callback, fn :github, _params, _session ->
        {:ok, %{user: %{"sub" => "new-user", "email" => "new@example.com"}, token: %{}}}
      end)

      conn =
        conn
        |> init_test_session(%{signup_gate_verified_at: System.system_time(:second)})
        |> get(~p"/auth/github/callback", code: "test-code")

      assert redirected_to(conn) == ~p"/signup"
      assert get_session(conn, :user_id) == nil
      assert get_session(conn, :signup_gate_verified_at) == nil
      assert Glossia.Repo.aggregate(Glossia.Accounts.User, :count) == count
    end

    test "existing users can still log in", %{conn: conn} do
      user = Glossia.TestHelpers.create_user("existing@example.com", "existing")

      Glossia.Repo.insert!(%Glossia.Accounts.Identity{
        user_id: user.id,
        provider: "github",
        provider_uid: "existing-user"
      })

      expect(Glossia.Auth, :callback, fn :github, _params, _session ->
        {:ok, %{user: %{"sub" => "existing-user"}, token: %{"access_token" => "test-token"}}}
      end)

      conn = get(conn, ~p"/auth/github/callback", code: "test-code")
      assert redirected_to(conn) == ~p"/dashboard"
      assert get_session(conn, :user_id) == user.id
    end
  end

  describe "POST /auth/dev-login" do
    test "returns to the protected page requested before sign-in", %{conn: conn} do
      user = Glossia.TestHelpers.create_user("dev@glossia.ai", "dev")
      return_to = "/dev/-/settings/models"

      conn =
        conn
        |> init_test_session(%{return_to: return_to})
        |> GlossiaWeb.AuthController.dev_login(%{})

      assert redirected_to(conn) == return_to
      assert get_session(conn, :user_id) == user.id
      assert get_session(conn, :return_to) == nil
    end
  end
end
