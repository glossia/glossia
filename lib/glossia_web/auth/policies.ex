defmodule GlossiaWeb.Auth.Policies do
  @moduledoc """
  This module provides a plug to load authenticated resources to use them
  to authorize requests.
  """

  # Modules
  use PolicyWonk.Policy
  use PolicyWonk.Enforce
  alias Glossia.Projects.Project

  def policy(assigns, :current_project) do
    case assigns[:current_project] do
      %Project{} ->
        :ok

      _ ->
        {:error, :current_project}
    end
  end

  def policy_error(conn, :current_project) do
    body = %{errors: [%{detail: "You need authenticate as a project"}]} |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, body)
  end
end
