defmodule Glossia.Foundation.Accounts.Web.Plugs.PoliciesPlug do
  # Modules
  alias Glossia.Foundation.Accounts.Core.Policies
  alias Glossia.Support.Utilities.Web.PathRememberer
  import Phoenix.Controller
  import Plug.Conn
  use Glossia.Foundation.Application.Web.Helpers.Shared, :verified_routes
  use PolicyWonk.Enforce

  defdelegate policy(assigns, action), to: Policies

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
