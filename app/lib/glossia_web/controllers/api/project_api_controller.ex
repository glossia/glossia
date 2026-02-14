defmodule GlossiaWeb.Api.ProjectApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Accounts.Account
  alias Glossia.Repo
  import Ecto.Query

  def index(conn, %{"handle" => handle} = params) do
    user = conn.assigns[:current_user]

    case Account |> where(handle: ^handle) |> Repo.one() do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case Glossia.Policy.authorize(:project_read, user, account) do
          :ok ->
            case Accounts.list_projects(account, params) do
              {:ok, {projects, meta}} ->
                json(conn, %{
                  projects:
                    Enum.map(projects, fn project ->
                      %{handle: project.handle, name: project.name}
                    end),
                  meta: serialize_meta(meta)
                })

              {:error, meta} ->
                conn
                |> put_status(:bad_request)
                |> json(%{errors: meta.errors})
            end

          {:error, :unauthorized} ->
            conn |> put_status(:forbidden) |> json(%{error: "not authorized"})
        end
    end
  end

  defp serialize_meta(%Flop.Meta{} = meta) do
    %{
      total_count: meta.total_count,
      total_pages: meta.total_pages,
      current_page: meta.current_page,
      page_size: meta.page_size,
      has_next_page?: meta.has_next_page?,
      has_previous_page?: meta.has_previous_page?
    }
  end
end
