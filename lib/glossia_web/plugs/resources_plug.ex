defmodule GlossiaWeb.Plugs.ResourcesPlug do
  alias Glossia.Accounts.Repository
  alias Glossia.Projects, as: Projects
  alias Glossia.Projects.Models.Project
  alias GlossiaWeb.Helpers.Auth
  use PolicyWonk.Load
  use PolicyWonk.Resource

  @spec resource(Plug.Conn.t(), :authenticated_project, any) ::
          {:ok, :authenticated_project, nil | Glossia.Projects.Models.Project.t()}
  def resource(conn, :authenticated_project, _) do
    with {:auth_header, "Bearer" <> " " <> token} <-
           {:auth_header, Plug.Conn.get_req_header(conn, "authorization") |> List.first()},
         {:authenticated_project, %Project{} = project} <-
           {:authenticated_project, Projects.get_project_from_token(String.trim(token))} do
      {:ok, :authenticated_project, project}
    else
      {:auth_header, nil} -> {:ok, :authenticated_project, nil}
      {:authenticated_project, nil} -> {:ok, :authenticated_project, nil}
    end
  end

  def resource(
        %Plug.Conn{params: %{"owner_handle" => owner, "project_handle" => project}},
        :url_project,
        _
      ) do
    case Projects.find_project_by_owner_and_project_handle(owner, project) do
      %Project{} = project ->
        {:ok, :url_project, project}

      _ ->
        {:ok, :url_project, nil}
    end
  end

  def resource(_conn, :url_project, _) do
    {:ok, :url_project, nil}
  end

  def resource_error(conn, detail) do
    body = %{errors: [%{detail: detail}]} |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, body)
  end
end
