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

  @spec resource(Plug.Conn.t(), :authenticated_project, any) ::
          {:ok, :authenticated_project, nil | Glossia.Projects.Models.Project.t()}
  @spec resource(Plug.Conn.t(), :authenticated_user, any) :: {:ok, :authenticated_user, any}
  def resource(conn, :authenticated_user, _) do
    with {user_token, _} when user_token != nil <- get_conn_token(conn),
         {:user, user} when user != nil <-
           {:user, Repository.get_user_by_session_token(user_token)} do
      {:ok, :authenticated_user, user}
    else
      _ ->
        {:ok, :authenticated_user, nil}
    end
  end

  @spec get_conn_token(conn :: Plug.Conn.t()) :: {String.t() | nil, Plug.Conn.t()}
  defp get_conn_token(conn) do
    if token = Plug.Conn.get_session(conn, :user_token) do
      {token, conn}
    else
      conn = Plug.Conn.fetch_cookies(conn, signed: [Auth.remember_me_cookie()])

      if token = conn.cookies[Auth.remember_me_cookie()] do
        {token, Auth.put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  def resource_error(conn, detail) do
    body = %{errors: [%{detail: detail}]} |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, body)
  end
end
