defmodule GlossiaWeb.Api.ProjectApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.Projects
  alias GlossiaWeb.Api.Serialization
  alias GlossiaWeb.ApiAuthorization

  def index(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :project_read, account) do
          {:ok, conn} ->
            case Projects.list_projects(account, params) do
              {:ok, {projects, meta}} ->
                json(conn, %{
                  projects:
                    Enum.map(projects, fn project ->
                      %{handle: project.handle, name: project.name}
                    end),
                  meta: Serialization.meta(meta)
                })

              {:error, meta} ->
                conn
                |> put_status(:bad_request)
                |> json(%{errors: meta.errors})
            end

          {:error, conn} ->
            conn
        end
    end
  end
end
