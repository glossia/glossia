defmodule GlossiaWeb.GithubInstallRedirectController do
  use GlossiaWeb, :controller

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "github_install_redirect",
    scale: :timer.minutes(1),
    limit: 10,
    by: :user,
    format: :text

  def redirect_to_install(conn, %{"handle" => handle}) do
    conn
    |> put_session(:wizard_return_to, "/#{handle}/-/projects/new?step=repo")
    |> put_session(:install_account_handle, handle)
    |> do_redirect_to_install(handle)
  end

  defp do_redirect_to_install(conn, handle) do
    case Glossia.Github.App.install_url() do
      {:ok, url} ->
        redirect(conn, external: url)

      {:error, :not_configured} ->
        conn
        |> put_flash(
          :error,
          gettext(
            "GitHub App is not configured. Set GITHUB_APP_ID, GITHUB_APP_PRIVATE_KEY, and GITHUB_APP_SLUG."
          )
        )
        |> redirect(to: ~p"/#{handle}/-/account")
    end
  end
end
