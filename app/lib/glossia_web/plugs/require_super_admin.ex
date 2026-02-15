defmodule GlossiaWeb.Plugs.RequireSuperAdmin do
  use GlossiaWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  use Gettext, backend: GlossiaWeb.Gettext

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && user.super_admin do
      conn
    else
      conn
      |> put_flash(:error, gettext("You do not have permission to access this page."))
      |> redirect(to: ~p"/dashboard")
      |> halt()
    end
  end
end
