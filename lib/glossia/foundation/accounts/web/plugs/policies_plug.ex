defmodule Glossia.Foundation.Accounts.Web.Plugs.PoliciesPlug do
  # Modules
  alias Glossia.Foundation.Accounts.Core.Policies
  import Phoenix.Controller
  import Plug.Conn
  use Glossia.Foundation.Application.Web.Helpers.Shared, :verified_routes
  use PolicyWonk.Enforce

  defdelegate policy(assigns, action), to: Policies

  def policy_error(conn, :authenticated_user_absent) do
    conn
    |> put_flash(:error, "You must log in to access this page.")
    |> maybe_store_return_to()
    |> redirect(to: ~p"/auth/login")
    |> halt()
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
