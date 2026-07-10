defmodule GlossiaWeb.AuthControllerTest do
  use GlossiaWeb.ConnCase, async: false

  setup do
    previous_providers = Application.get_env(:glossia, :oauth_providers, [])

    on_exit(fn ->
      Application.put_env(:glossia, :oauth_providers, previous_providers)
    end)
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

    test "links to sign up", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")
      response = html_response(conn, 200)

      assert response =~ "Log in to Glossia"
      assert response =~ ~s(href="/signup")
      assert response =~ "Sign up"
      refute response =~ "Join the waitlist"
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
          title: "Log in to Glossia",
          subtitle: "Welcome back. Choose a sign-in method to continue.",
          switch_prompt: "New to Glossia?",
          switch_href: "/signup",
          switch_label: "Sign up"
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

      assert response =~ "Sign up for Glossia"
      assert response =~ "Choose a provider to create your account and start using Glossia."
      assert response =~ ~s(href="/auth/login")
      assert response =~ "Log in"
      refute response =~ "Join the waitlist"
    end
  end
end
