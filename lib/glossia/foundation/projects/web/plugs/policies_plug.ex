defmodule Glossia.Foundation.Projects.Web.Plugs.PoliciesPlug do
  # Modules
  use PolicyWonk.Enforce
  import Plug.Conn
  alias Glossia.Foundation.Projects.Core.Policies

  defdelegate policy(assigns, action), to: Policies

  @spec policy_error(Plug.Conn.t(), :unauthorized) :: Plug.Conn.t()
  def policy_error(conn, :unauthorized) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(401, "Unauthorized")
  end
end
