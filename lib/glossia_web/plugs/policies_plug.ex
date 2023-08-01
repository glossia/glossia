defmodule GlossiaWeb.Plugs.ResourcesPlug do
  @moduledoc """
  This module provides a plug to load authenticated resources to use them
  to authorize requests.
  """

  # Modules
  use PolicyWonk.Policy
  use PolicyWonk.Enforce
  alias Glossia.Projects
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
    MyAppWeb.ErrorHandlers.unauthenticated(conn, "Must be logged in")
  end
end
