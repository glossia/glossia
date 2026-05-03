defmodule GlossiaWeb.Api.ProjectApiController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.ChangesetErrors
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
                  projects: Enum.map(projects, &serialize_project/1),
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

  def create(conn, %{"handle" => handle} = params) do
    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "account not found"})

      account ->
        case ApiAuthorization.authorize(conn, :project_write, account) do
          {:ok, conn} ->
            attrs = %{
              handle: params["project_handle"],
              name: params["name"]
            }

            user = conn.assigns[:current_user]

            case Projects.create_project(account, attrs, actor: user, via: :api) do
              {:ok, project} ->
                conn
                |> put_status(:created)
                |> json(serialize_project(project))

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: ChangesetErrors.to_map(changeset)})
            end

          {:error, conn} ->
            conn
        end
    end
  end

  defp serialize_project(project) do
    %{
      handle: project.handle,
      name: project.name,
      github_repo_full_name: project.github_repo_full_name,
      setup_status: project.setup_status,
      inserted_at: project.inserted_at
    }
  end
end
