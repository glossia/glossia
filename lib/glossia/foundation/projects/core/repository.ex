defmodule Glossia.Foundation.Projects.Core.Repository do
  # Modules
  @behaviour __MODULE__.Behaviour
  alias Glossia.Foundation.Projects.Core.Models.Project
  alias Glossia.Foundation.Accounts.Core.User

  @doc """
  Given a user, it returns a default project. This is useful to redirect the user to the default project when they log in.

  ## Parameters
      * `user` - The user to get the default project for
  """
  @spec get_user_default_project(User.t()) :: Project.t() | nil
  def get_user_default_project(_user) do

  end

  defmodule Behaviour do
    @callback get_user_default_project(User.t()) :: Project.t() | nil
  end
end
