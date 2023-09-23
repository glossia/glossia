defmodule Glossia.Foundation.Projects.Web.Plugs.PoliciesPlug do
  # Modules
  use PolicyWonk.Enforce
  alias Glossia.Foundation.Projects.Core.Policies

  defdelegate policy(assigns, action), to: Policies
end
