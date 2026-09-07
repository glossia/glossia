defmodule GlossiaWeb.Plugs.AnalyticsCors do
  @moduledoc """
  Permissive CORS for the public analytics collect endpoint.

  The endpoint accepts no credentials and no cookies, so
  `Access-Control-Allow-Origin: *` is safe and keeps the SDK trivial to embed.
  Preflight `OPTIONS` requests are short-circuited to a 204 before routing.
  """

  @behaviour Plug
  import Plug.Conn

  @headers ~w(content-type)

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%{method: "OPTIONS"} = conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "POST, OPTIONS")
    |> put_resp_header("access-control-allow-headers", Enum.join(@headers, ", "))
    |> put_resp_header("access-control-max-age", "86400")
    |> resp(204, "")
    |> halt()
  end

  def call(conn, _opts) do
    put_resp_header(conn, "access-control-allow-origin", "*")
  end
end
