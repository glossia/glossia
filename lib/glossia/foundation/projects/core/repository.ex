defmodule Glossia.Foundation.Projects.Core.Repository do
  # Modules
  @behaviour __MODULE__.Behaviour
  alias Glossia.Foundation.Database.Core.Repo
  alias Glossia.Foundation.Projects.Core.Models.Project
  alias Glossia.Foundation.Accounts.Core.Models.User
  # alias Glossia.Foundation.Accounts.Core.Models.OrganizationUser
  # alias Glossia.Foundation.Accounts.Core.Models.Organization
  # import Ecto.Query, only: [from: 2]

  @doc """
  Given a user, it returns a default project. This is useful to redirect the user to the default project when they log in.

  ## Parameters
      * `user` - The user to get the default project for
  """
  @spec get_user_default_project(User.t()) :: Project.t() | nil
  def get_user_default_project(_user) do
    # user_accounts =
    #   from(a in Accounts,
    #     join: o in Organization,
    #     join: o in
    #     join: ou in OrganizationUser,

    #     on: o.id == ou.organization_id,
    #     join: u in User,
    #     on: u.id == ou.user_id,
    #     where: u.user_id == ^user.id,
    #     select: {o.id, o.name}
    #   )

    # 1. Fetch the user organizations
    # 2. Fetch the user's account
  end

  @spec update_last_visited_project_for_user(User.t(), Project.t()) :: User.t()
  def update_last_visited_project_for_user(user, project) do
    Repo.update!(
      user
      |> Ecto.Changeset.cast(%{last_visited_project_id: project.id}, [:last_visited_project_id])
    )
  end

  defmodule Behaviour do
    @callback get_user_default_project(User.t()) :: Project.t() | nil
    @callback update_last_visited_project_for_user(User.t(), Project.t()) :: User.t()
  end
end
