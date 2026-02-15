defmodule GlossiaWeb.Plugs.RequireApiAuth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(401, JSON.encode!(%{error: "unauthorized"}))
      |> halt()
    end
  end
end
