defmodule GlossiaWeb.Plugs.RequireAccess do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && user.account && user.account.has_access do
      conn
    else
      conn
      |> redirect(to: "/interest")
      |> halt()
    end
  end
end
