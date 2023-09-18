defmodule Glossia.Foundation.Projects.Core.Repository do
  # Modules
  @behaviour __MODULE__.Behaviour
  alias Glossia.Foundation.Database.Core.Repo
  alias Glossia.Foundation.Projects.Core.Models.Project
  alias Glossia.Foundation.Accounts.Core.Models.User
  # alias Glossia.Foundation.Accounts.Core.Models.OrganizationUser
  # alias Glossia.Foundation.Accounts.Core.Models.Organization
  import Ecto.Query, only: [from: 2]

  @doc """
  Given a project id it returns it if it exists in the database.
  Otherwise it returns nil.

  ## Parameters

      * `id` - The project id.
  """
  @spec get_project_by_id(number()) :: Project.t() | nil
  def get_project_by_id(id) do
    Repo.get(Project, id)
  end

  @doc """
  Given a list of accounts it returns the projects of those accounts.

  ## Parameters

      * `accounts` - The accounts.
  """
  @spec get_account_projects([Account.t()]) :: [Project.t()]
  def get_account_projects(accounts) do
    Repo.all(
      from p in Project,
        where: p.account_id in ^Enum.map(accounts, & &1.id),
        order_by: [desc: p.inserted_at]
    )
  end

  @doc """
  Given a user and a project it has last visited, it updates the user's
  last visited project.

  ## Parameters
        * `user` - The user.
        * `project` - The project.
  """
  @spec update_last_visited_project_for_user(User.t(), Project.t()) :: User.t()
  def update_last_visited_project_for_user(user, project) do
    Repo.update!(
      user
      |> Ecto.Changeset.cast(%{last_visited_project_id: project.id}, [:last_visited_project_id])
    )
  end

  defmodule Behaviour do
    @callback get_account_projects([Account.t()]) :: [Project.t()]
    @callback get_project_by_id(number()) :: Project.t() | nil
    @callback update_last_visited_project_for_user(User.t(), Project.t()) :: User.t()
  end
end
