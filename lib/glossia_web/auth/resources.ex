defmodule GlossiaWeb.Auth.Resources do
  @moduledoc """
  This module provides a plug to load authenticated resources to use them
  to authorize requests.
  """

  # Modules
  use PolicyWonk.Resource
  use PolicyWonk.Load
  alias Glossia.Projects
  alias Glossia.Projects.Project

  def resource(conn, :current_project, _) do
    with {:auth_header, "Bearer" <> " " <> token} <-
           {:auth_header, Plug.Conn.get_req_header(conn, "authorization") |> List.first()},
         {:current_project, %Project{} = project} <-
           {:current_project, Projects.get_project_from_token(String.trim(token))} do
      {:ok, :current_project, project}
    else
      {:auth_header, nil} -> {:ok, :current_project, nil}
      {:current_project, nil} -> {:ok, :current_project, nil}
    end
  end

  def resource_error(conn, detail) do
    body = %{errors: [%{detail: detail}]} |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, body)
  end
end
