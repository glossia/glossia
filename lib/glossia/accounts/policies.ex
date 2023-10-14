defmodule Glossia.Accounts.Policies do
  # Modules
  use PolicyWonk.Policy
  use GlossiaWeb.Helpers.Shared, :verified_routes
  alias Glossia.Accounts.Models.User

  # Policy: {:authenticated_user_present}

  def policy(_, :authenticate_user_is_admin) do
    {:error, :authenticated_user_is_not_admin}
  end

  def policy_error(conn, _) do
    # Handled at the plug level
    conn
  end
end
