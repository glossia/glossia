defmodule GlossiaWeb.Plugs.RequireAuth do
  use GlossiaWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  use Gettext, backend: GlossiaWeb.Gettext

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      return_to = build_return_path(conn)

      conn
      |> put_session(:return_to, return_to)
      |> put_flash(:info, gettext("Sign in to continue."))
      |> redirect(to: ~p"/auth/login")
      |> halt()
    end
  end

  defp build_return_path(%{request_path: path, query_string: ""}), do: path
  defp build_return_path(%{request_path: path, query_string: qs}), do: "#{path}?#{qs}"
end
