defmodule GlossiaWeb.Plugs.SaveLastVisitedProjectPlug do
  @moduledoc false

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(%{assigns: %{url_project: project}} = conn, _opts) do
    authenticated_user = GlossiaWeb.Auth.authenticated_user(conn)

    with {:project, %Glossia.Projects.Project{} = project} <- {:project, project},
         {:authorized, true} <-
           {:authorized,
            Glossia.Authorization.permit?(Glossia.Projects, :read, authenticated_user, project)},
         {:last_visited_project_updated, :ok} <-
           {:last_visited_project_updated,
            Glossia.Projects.Repository.update_last_visited_project_for_user(
              authenticated_user,
              project
            )} do
      conn
    else
      {:project, nil} -> conn
      {:authorized, false} -> conn
      {:last_visited_project_updated, :ok} -> conn
    end
  end

  def call(conn, _opts), do: conn
end
