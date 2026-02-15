defmodule GlossiaWeb.Plugs.RequireSuperAdminApi do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && user.super_admin do
      conn
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        403,
        JSON.encode!(%{error: "forbidden", message: "Super admin access required"})
      )
      |> halt()
    end
  end
end
