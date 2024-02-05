defmodule Glossia.Projects.Repository do
  @moduledoc false

  alias Glossia.Accounts.User
  alias Glossia.Projects.Project
  alias Glossia.Repo

  @doc ~S"""
  Given a user and a project it has last visited, it updates the user's
  last visited project.

  ## Parameters
        * `user` - The user.
        * `project` - The project.
  """
  @spec update_last_visited_project_for_user(User.t(), Project.t()) :: :ok
  def update_last_visited_project_for_user(user, project) do
    {:ok, _} =
      Repo.update(
        user
        |> Ecto.Changeset.cast(%{last_visited_project_id: project.id}, [:last_visited_project_id])
      )

    :ok
  end
end
