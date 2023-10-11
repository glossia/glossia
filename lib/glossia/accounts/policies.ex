defmodule Glossia.Accounts.Policies do
  # Modules
  use PolicyWonk.Policy
  use GlossiaWeb.Helpers.Shared, :verified_routes
  alias Glossia.Accounts.Models.User

  # Policy: {:authenticated_user_present}

  @spec policy(any(), :authenticate_user_is_admin | :authenticated_user_present) ::
          :ok | {:error, :authenticated_user_absent | :authenticated_user_is_not_admin}
  def policy(%{authenticated_user: %User{}}, :authenticated_user_present) do
    :ok
  end

  def policy(_, :authenticated_user_present) do
    {:error, :authenticated_user_absent}
  end

  def policy(%{authenticated_user: %User{} = user}, :authenticate_user_is_admin) do
    if user.role == :admin do
      :ok
    else
      {:error, :authenticated_user_is_not_admin}
    end
  end

  def policy(_, :authenticate_user_is_admin) do
    {:error, :authenticated_user_is_not_admin}
  end

  def policy_error(conn, _) do
    # Handled at the plug level
    conn
  end
end
