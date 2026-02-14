defmodule GlossiaWeb.Plugs.RequireAuth do
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
      |> put_flash(:error, gettext("You must sign in to access this page."))
      |> redirect(to: "/auth/login")
      |> halt()
    end
  end

  defp build_return_path(%{request_path: path, query_string: ""}), do: path
  defp build_return_path(%{request_path: path, query_string: qs}), do: "#{path}?#{qs}"
end
