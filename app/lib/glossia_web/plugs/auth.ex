defmodule GlossiaWeb.Plugs.Auth do
  import Plug.Conn

  alias Glossia.Accounts
  alias Glossia.Accounts.Scope

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    conn =
      if user_id do
        case Accounts.get_user(user_id) do
          nil ->
            conn
            |> delete_session(:user_id)
            |> assign(:current_scope, nil)
            |> assign(:current_user, nil)

          user ->
            conn
            |> assign(:current_scope, Scope.for_user(user))
            |> assign(:current_user, user)
        end
      else
        conn
        |> assign(:current_scope, nil)
        |> assign(:current_user, nil)
      end

    conn
    |> assign(:impersonating_from, get_session(conn, :impersonating_from))
    |> assign(:impersonation_reason, get_session(conn, :impersonation_reason))
  end
end
