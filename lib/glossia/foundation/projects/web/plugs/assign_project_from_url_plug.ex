defmodule Glossia.Foundation.Projects.Web.Plugs.AssignProjectFromURLPlug do
  @moduledoc """
  This plug will extract the project owner and handle from the URL and load the project from the database.
  """

  # Modules
  import Plug.Conn
  alias Plug.Conn
  alias Glossia.Foundation.Projects.Core, as: Projects
  alias Glossia.Foundation.Projects.Core.Models.Project

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(
        %Conn{params: %{"owner_handle" => owner, "project_handle" => project}} = conn,
        _opts
      ) do
    case Projects.find_project_by_owner_and_project_handle(owner, project) do
      %Project{} = project ->
        assign(conn, :url_project, project)
      _ ->
        conn
    end
  end

  def call(conn, _opts) do
    conn
  end
end
