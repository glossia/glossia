defmodule Glossia.Foundation.Projects.Core.Policies do
  # Modules
  use PolicyWonk.Policy
  use Glossia.Foundation.Application.Web.Helpers.Shared, :verified_routes
  alias Glossia.Foundation.Projects.Core.Models.Project

  # Policy: {:authenticated_project_present}

  def policy(%{authenticated_project: %Project{}}, :authenticated_project_present) do
    :ok
  end

  def policy(_, :authenticated_project_present) do
    {:error, :unauthorized}
  end

  # Policy: {:read, :project}

  def policy(%{project: %{visibility: :public}}, {:read, :project}) do
    :ok
  end

  def policy(%{project: %Project{} = project, user: user}, {:read, :project}) do
    if Glossia.Foundation.Accounts.Core.Repository.get_user_and_organization_accounts(user)
       |> Enum.map(& &1.id)
       |> Enum.member?(project.account_id) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  def policy(%{project: nil, user: _}, {:read, :project}) do
    {:error, :unauthorized}
  end

  def policy(
        %{url_project: url_project} = assigns,
        {:read, :project}
      ) do
    policy(Map.merge(%{project: url_project}, assigns), {:read, :project})
  end

  def policy(
        %{authenticated_user: authenticated_user} = assigns,
        {:read, :project}
      ) do
    policy(Map.merge(%{user: authenticated_user}, assigns), {:read, :project})
  end

  def policy(
        %{url_project: url_project, authenticated_user: authenticated_user} = assigns,
        {:read, :project}
      ) do
    policy(
      Map.merge(%{user: authenticated_user, project: url_project}, assigns),
      {:read, :project}
    )
  end

  def policy(_, {:read, :project}) do
    {:error, :unauthorized}
  end

  def policy_error(conn, :unauthorized) do
    # Handled at the plug level
    conn
  end
end
