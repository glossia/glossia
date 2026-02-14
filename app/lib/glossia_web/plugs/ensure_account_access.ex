defmodule GlossiaWeb.Plugs.EnsureAccountAccess do
  @moduledoc """
  Extracts the account handle from params, looks up the account,
  and checks read/write access via the LetMe policy system.

  Assigns:
    - `@account` - the Account struct
    - `@handle` - the account handle string
    - `@can_write` - boolean, whether the current user can write
    - `@accounts` - list of user's accounts (empty when anonymous)
  """

  import Plug.Conn

  alias Glossia.Accounts

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"handle" => handle}} = conn, _opts) do
    user = conn.assigns[:current_user]

    case Accounts.get_account_by_handle(handle) do
      nil ->
        conn
        |> put_status(404)
        |> Phoenix.Controller.put_view(GlossiaWeb.ErrorHTML)
        |> Phoenix.Controller.render(:"404")
        |> halt()

      account ->
        if Glossia.Policy.authorize?(:project_read, user, account) do
          can_write = Glossia.Policy.authorize?(:project_write, user, account)

          accounts =
            if user do
              {:ok, {accounts, _meta}} = Accounts.list_user_accounts(user)
              accounts
            else
              []
            end

          conn
          |> assign(:account, account)
          |> assign(:handle, handle)
          |> assign(:can_write, can_write)
          |> assign(:accounts, accounts)
        else
          conn
          |> put_status(404)
          |> Phoenix.Controller.put_view(GlossiaWeb.ErrorHTML)
          |> Phoenix.Controller.render(:"404")
          |> halt()
        end
    end
  end

  def call(conn, _opts) do
    conn
    |> put_status(404)
    |> Phoenix.Controller.put_view(GlossiaWeb.ErrorHTML)
    |> Phoenix.Controller.render(:"404")
    |> halt()
  end
end
