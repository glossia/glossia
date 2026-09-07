defmodule GlossiaWeb.AccountRouterController do
  use GlossiaWeb, :controller

  alias Glossia.Accounts

  def show(conn, %{"handle" => handle, "path" => path}) do
    user = conn.assigns[:current_user]

    case Accounts.get_account_by_handle(handle) do
      nil ->
        raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account

      account ->
        if Glossia.Authz.authorize?(:project_read, user, account) do
          accounts =
            if user do
              {:ok, {accounts, _meta}} = Accounts.list_user_accounts(user)
              accounts
            else
              []
            end

          can_write = Glossia.Authz.authorize?(:project_write, user, account)
          is_admin = Glossia.Authz.authorize?(:project_admin, user, account)

          conn =
            conn
            |> assign(:account, account)
            |> assign(:handle, handle)
            |> assign(:accounts, accounts)
            |> assign(:show_sidebar, user != nil)
            |> assign(:sidebar_context, :account)
            |> assign(:sidebar_project, nil)
            |> assign(:can_write, can_write)
            |> assign(:is_admin, is_admin)
            |> assign(:live_action, :activity)

          case Glossia.Extensions.account_router().resolve(conn, handle, path) do
            %Plug.Conn{} = conn -> conn
            :not_found -> raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
          end
        else
          raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
        end
    end
  end
end
