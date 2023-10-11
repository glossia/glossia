defmodule GlossiaWeb.Plugs.PoliciesPlug do
  # Modules
  alias Glossia.Accounts.Policies
  alias GlossiaWeb.Support.PathRememberer
  import Phoenix.Controller
  import Plug.Conn
  use GlossiaWeb.Helpers.Shared, :verified_routes
  use PolicyWonk.Enforce

  defdelegate policy(assigns, action), to: Policies

  @spec policy_error(Plug.Conn.t(), :unauthorized) :: Plug.Conn.t()
  def policy_error(conn, :unauthorized) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(401, "Unauthorized")
  end

  def policy_error(conn, :authenticated_user_absent) do
    conn
    |> put_flash(:error, "You must log in to access this page.")
    |> PathRememberer.remember_current_path()
    |> redirect(to: ~p"/auth/login")
    |> halt()
  end

  def policy_error(conn, :authenticated_user_is_not_admin) do
    conn
    |> put_flash(:error, "You are not authorized to visit this page")
    |> redirect(to: ~p"/")
    |> halt()
  end
end
