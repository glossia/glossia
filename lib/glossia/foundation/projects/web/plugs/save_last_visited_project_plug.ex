defmodule Glossia.Foundation.Projects.Web.Plugs.SaveLastVisitedProjectPlug do
  @moduledoc """
  If there is an authenticated user
  """

  # Modules
  alias Glossia.Foundation.Projects.Core.Policies

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(%{assigns: %{url_project: project}} = conn, _opts) do
    authenticated_user = Glossia.Foundation.Accounts.Web.Helpers.Auth.authenticated_user(conn)

    case Policies.policy(%{user: authenticated_user, project: project}, {:read, :project}) do
      :ok ->
        Glossia.Foundation.Projects.Core.Repository.update_last_visited_project_for_user(
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
