defmodule Glossia.Localizations.Policies do
  @moduledoc """
  This module provides a plug to load authenticated resources to use them
  to authorize requests.
  """

  # Modules
  use PolicyWonk.Policy
  use PolicyWonk.Enforce
  alias Glossia.Projects.Models.Project

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

  def policy_error(conn, _) do
    # Handled at the plug level
    conn
  end
end