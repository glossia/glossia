defmodule GlossiaWeb.Plugs.InternalBabelTransport do
  @moduledoc false

  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  def init(opts), do: opts

  # The Service maps its logical port (443) to the private listener (4051),
  # so the request port does not reliably identify the listener. Network
  # policy keeps this encrypted listener reachable only from Babel's service account.
  def call(%Plug.Conn{scheme: :https} = conn, _opts), do: conn

  def call(conn, _opts) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "not_found"})
    |> halt()
  end
end
