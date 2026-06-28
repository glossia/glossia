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

    test "redirects when a known provider is not configured", %{conn: conn} do
      Application.put_env(:glossia, :oauth_providers, [])

      conn = get(conn, ~p"/auth/github")

      assert redirected_to(conn) == ~p"/auth/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "That sign-in method is not available."
    end

    test "renders development sign-in as the seeded test user" do
      html =
        %{flash: %{}, dev_routes: true, providers: []}
        |> GlossiaWeb.AuthHTML.login()
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert html =~ "Sign in as test user"
      refute html =~ "Continue with GitHub"
      refute html =~ "Continue with GitLab"
    end
  end
end
