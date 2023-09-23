defmodule Glossia.Foundation.Accounts.Web.Plugs.PoliciesPlug do
  # Modules
  use PolicyWonk.Enforce
  alias Glossia.Foundation.Accounts.Core.Policies

  defdelegate policy(assigns, action), to: Policies
end
