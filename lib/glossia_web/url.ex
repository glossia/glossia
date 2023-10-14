defmodule GlossiaWeb.URL do
  import Plug.Conn

  @loaded_project_key :url_project

  def init(:load_project = opts), do: opts

  def call(%Plug.Conn{params: %{"owner_handle" => owner, "project_handle" => project}} = conn, :load_project) do
    case Glossia.Projects.find_project_by_owner_and_project_handle(owner, project) do
      %Glossia.Projects.Models.Project{} = project ->
        assign(conn, @loaded_project_key, project)
      _ ->
        conn
    end
  end

  def call(conn, :load_project), do: conn

  def url_project(conn), do: conn.assigns[@loaded_project_key]
  def url_project?(conn), do: conn.assigns[@loaded_project_key] != nil
end
