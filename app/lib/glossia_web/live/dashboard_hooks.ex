defmodule GlossiaWeb.DashboardHooks do
  @moduledoc """
  LiveView on_mount hooks replicating the dashboard plug chain.

  Hooks:
    - `:load_user` - loads current_user from session
    - `:load_account` - loads account from handle param, checks read access
    - `:check_write` - checks write access, assigns can_write
  """

  import Phoenix.Component, only: [assign: 3]

  alias Glossia.Accounts

  def on_mount(:load_user, _params, session, socket) do
    user =
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user(user_id)
      end

    {:cont, assign(socket, :current_user, user)}
  end

  def on_mount(:load_account, params, _session, socket) do
    handle = params["handle"]
    user = socket.assigns[:current_user]

    case Accounts.get_account_by_handle(handle) do
      nil ->
        raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account

      account ->
        if Glossia.Policy.authorize?(:project_read, user, account) do
          accounts =
            if user do
              {:ok, {accounts, _meta}} = Accounts.list_user_accounts(user)
              accounts
            else
              []
            end

          {:cont,
           socket
           |> assign(:account, account)
           |> assign(:handle, handle)
           |> assign(:accounts, accounts)}
        else
          if user do
            raise Ecto.NoResultsError, queryable: Glossia.Accounts.Account
          else
            {:halt, Phoenix.LiveView.redirect(socket, to: "/auth/login")}
          end
        end
    end
  end

  def on_mount(:check_write, _params, _session, socket) do
    user = socket.assigns[:current_user]
    account = socket.assigns[:account]
    can_write = Glossia.Policy.authorize?(:project_write, user, account)
    is_admin = Glossia.Policy.authorize?(:project_admin, user, account)

    {:cont,
     socket
     |> assign(:can_write, can_write)
     |> assign(:is_admin, is_admin)}
  end
end
