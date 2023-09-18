defmodule Glossia.Foundation.Projects.Web.Policies do
  # Modules
  use PolicyWonk.Policy
  use Glossia.Foundation.Application.Web.Helpers.Shared, :verified_routes

  def policy(assigns, {:show, :project}) do
    project = assigns[:url_project]
    user = assigns[:authenticated_user]

    case {project, user} do
      {nil, _} ->
        :ok

      # It's only possible to access public projects
      # for unauthenticated users
      {_, %{visibility: :public}} ->
        :ok

      {project, user} ->
        # Only if the user has access to the project
        :ok

      _ ->
        {:error, :unauthorized}
    end
  end

  def policy_error(conn, :unauthorized) do
    conn
    |> Plug.Conn.send_resp(401, "Unauthorized")
  end
end
