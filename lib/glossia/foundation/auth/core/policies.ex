defmodule Glossia.Foundation.Auth.Core.Policies do
  use PolicyWonk.Policy
  use PolicyWonk.Enforce

  alias Glossia.Foundation.Accounts.Core.Models.User

  def policy(%{authenticated_user: %User{}}, {:read, :admin}) do
    :ok
  end
end
