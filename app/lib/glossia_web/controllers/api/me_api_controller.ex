defmodule GlossiaWeb.Api.MeApiController do
  use GlossiaWeb, :controller
  alias Glossia.Accounts
  alias Glossia.ChangesetErrors
  alias Glossia.Repo
  alias GlossiaWeb.ApiAuthorization

  def show(conn, _params) do
    user = conn.assigns.current_user

    case ApiAuthorization.authorize(conn, :user_read, user) do
      {:ok, conn} ->
        profile(conn, user)

      {:error, conn} ->
        conn
    end
  end

  def update_fluent_languages(conn, _params) do
    user = conn.assigns.current_user

    case ApiAuthorization.authorize(conn, :user_write, user) do
      {:ok, conn} ->
        case conn.body_params do
          %{"fluent_languages" => languages} = body when map_size(body) == 1 ->
            case Accounts.update_user_fluent_languages(user, languages) do
              {:ok, user} ->
                profile(conn, user)

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: ChangesetErrors.to_map(changeset)})
            end

          _ ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              errors: %{fluent_languages: ["must be the only field in the request body"]}
            })
        end

      {:error, conn} ->
        conn
    end
  end

  defp profile(conn, user) do
    user = Repo.preload(user, :account)

    json(conn, %{
      user: %{
        id: user.id,
        name: user.name,
        email: user.email,
        handle: user.account.handle,
        fluent_languages: user.fluent_languages
      },
      server_version: to_string(Application.spec(:glossia, :vsn))
    })
  end
end
