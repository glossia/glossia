defmodule GlossiaWeb.Plugs.RequireSuperAdminApi do
  import Plug.Conn

  alias Glossia.Authz

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && Authz.authorize?(:admin_read, user, nil) do
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
