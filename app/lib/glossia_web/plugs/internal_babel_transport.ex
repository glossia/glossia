defmodule GlossiaWeb.Plugs.InternalBabelTransport do
  @moduledoc false

  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  @babel_port 4051

  def init(opts), do: opts

  def call(%Plug.Conn{scheme: :https, port: @babel_port} = conn, _opts), do: conn

  def call(conn, _opts) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "not_found"})
    |> halt()
  end
end
