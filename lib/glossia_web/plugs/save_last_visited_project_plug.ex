defmodule GlossiaWeb.Plugs.SaveLastVisitedProjectPlug do
  @moduledoc """
  If there is an authenticated user
  """

  # Modules
  alias Glossia.Projects.Policies

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(%{assigns: %{url_project: project}} = conn, _opts) do
    authenticated_user = GlossiaWeb.Auth.authenticated_user(conn)

    case Policies.policy(%{user: authenticated_user, project: project}, {:read, :project}) do
      :ok ->
        Glossia.Projects.Repository.update_last_visited_project_for_user(
          authenticated_user,
          project
        )

        conn

      _ ->
        conn
    end
  end

  def call(conn, _opts), do: conn
end
