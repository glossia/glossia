defmodule Glossia.Projects.Policies do
  # Modules
  use PolicyWonk.Policy
  use GlossiaWeb.Helpers.Shared, :verified_routes
  alias Glossia.Projects.Models.Project

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
    if Glossia.Accounts.Repository.get_user_and_organization_accounts(user)
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
        %{url_project: _} = assigns,
        {:read, :project}
      ) do
    {project, assigns} = assigns |> Map.pop(:url_project)
    policy(Map.merge(%{project: project}, assigns), {:read, :project})
  end

  def policy(
        %{authenticated_user: _} = assigns,
        {:read, :project}
      ) do
    {user, assigns} = assigns |> Map.pop(:authenticated_user)

    policy(Map.merge(%{user: user}, assigns), {:read, :project})
  end

  def policy(
        %{url_project: _, authenticated_user: _} = assigns,
        {:read, :project}
      ) do
    {user, assigns} = assigns |> Map.pop(:authenticated_user)
    {project, assigns} = assigns |> Map.pop(:url_project)

    policy(
      Map.merge(%{user: user, project: project}, assigns),
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
