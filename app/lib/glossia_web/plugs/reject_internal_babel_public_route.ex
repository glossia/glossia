defmodule GlossiaWeb.Plugs.RejectInternalBabelPublicRoute do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:not_found, ~s({"error":"not_found"}))
    |> halt()
  end
end
