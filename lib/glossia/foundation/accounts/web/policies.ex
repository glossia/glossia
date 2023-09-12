defmodule Glossia.Foundation.Accounts.Web.Policies do
  @moduledoc """
  This module provides a plug to load authenticated resources to use them
  to authorize requests.
  """

  # Modules
  use PolicyWonk.Policy
  use PolicyWonk.Enforce
  alias Glossia.Foundation.Projects.Core.Project

  def policy(assigns, :authenticated_project) do
    case assigns[:authenticated_project] do
      %Project{} ->
        :ok

      _ ->
        {:error, :unauthorized}
    end
  end

  def policy(assigns, {:create, :localization_request}) do
    policy(assigns, {[:create], :localization_request})
  end

  def policy(assigns, {actions, :localization_request}) when is_list(actions) do
    case {assigns[:authenticated_project], assigns[:url_project]} do
      {%Project{} = authenticated_project, %Project{} = url_project} ->
        # The authenticated project and the project in the URL must be the same
        if authenticated_project.id == url_project.id, do: :ok, else: {:error, :unauthorized}

      _ ->
        {:error, :unauthorized}
    end
  end

  # Errors

  def policy_error(conn, :unauthorized) do
    body =
      %{errors: [%{detail: "You need to be authenticated to access this resource"}]}
      |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, body)
  end
end
