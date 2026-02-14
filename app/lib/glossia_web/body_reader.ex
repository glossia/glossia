defmodule GlossiaWeb.BodyReader do
  @moduledoc false

  import Plug.Conn

  def read_body(conn, opts) do
    do_read_body(conn, opts, [])
  end

  defp do_read_body(conn, opts, acc) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        full_body = IO.iodata_to_binary(Enum.reverse([body | acc]))
        conn = assign(conn, :raw_body, full_body)
        {:ok, full_body, conn}

      {:more, body, conn} ->
        do_read_body(conn, opts, [body | acc])

      {:error, _} = error ->
        error
    end
  end
end

