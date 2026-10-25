defmodule GlossiaWeb.Api.MeApiController do
  use GlossiaWeb, :controller
  alias Glossia.Repo
  alias GlossiaWeb.ApiAuthorization

  def show(conn, _params) do
    user = conn.assigns.current_user

    case ApiAuthorization.authorize(conn, :user_read, user) do
      {:ok, conn} ->
        user = Repo.preload(user, :account)

        json(conn, %{
          user: %{id: user.id, name: user.name, email: user.email, handle: user.account.handle},
          server_version: to_string(Application.spec(:glossia, :vsn))
        })

      {:error, conn} ->
        conn
    end
  end
end
