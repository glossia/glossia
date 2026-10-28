defmodule GlossiaEnterpriseWeb.OrganizationSession do
  @moduledoc false
  use GlossiaWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3, fetch_flash: 2]
  use Gettext, backend: GlossiaEnterpriseWeb.Gettext
  alias Glossia.Accounts
  alias GlossiaEnterprise.OrganizationAuthentication

  def check_session(conn) do
    with %{"handle" => handle} <- conn.path_params,
         account when not is_nil(account) <- Accounts.get_account_by_handle(handle) do
      check_session(conn, account)
    else
      _ -> conn
    end
  end

  def check_session(conn, account) do
    with user when not is_nil(user) <- conn.assigns[:current_user],
         false <-
           OrganizationAuthentication.session_authorized?(
             account,
             user,
             get_session(conn, :organization_sso)
           ) do
      return_to = %URI{
        path: conn.request_path,
        query: if(conn.query_string == "", do: nil, else: conn.query_string)
      }

      conn
      |> put_session(:return_to, URI.to_string(return_to))
      |> fetch_flash([])
      |> put_flash(:info, gettext("Sign in with your organization to access this account."))
      |> redirect(to: ~p"/auth/login")
      |> halt()
    else
      _ -> conn
    end
  end
end
