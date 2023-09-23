defmodule Glossia.Foundation.Projects.Web.Plugs.PoliciesPlug do
  # Modules
  use PolicyWonk.Enforce
  alias Glossia.Foundation.Projects.Core.Policies

  defdelegate policy(assigns, action), to: Policies

  def policy_error(conn, :unauthorized) do
    conn
    |> Plug.Conn.send_resp(401, "Unauthorized")
  end
end
