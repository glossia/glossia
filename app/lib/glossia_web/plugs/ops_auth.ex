defmodule GlossiaWeb.Plugs.OpsAuth do
  @moduledoc false

  import Phoenix.Controller, only: [redirect: 2]

  alias Glossia.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> redirect(to: "/auth/login")
        |> Plug.Conn.halt()

      user ->
        if Accounts.super_admin?(user) do
          conn
        else
          conn
          |> Plug.Conn.send_resp(403, "Operations access requires the super administrator role")
          |> Plug.Conn.halt()
        end
    end
  end
end
