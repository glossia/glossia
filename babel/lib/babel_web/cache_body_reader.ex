defmodule BabelWeb.CacheBodyReader do
  @moduledoc """
  Caches the raw request body on paths where a controller downstream of
  `Plug.Parsers` needs it verbatim (Sentry envelope ingestion). For
  every other path the reader is a straight pass-through, so the cost
  is a single conditional per request.
  """

  def read_body(conn, opts) do
    read_chunks(conn, opts, [])
  end

  defp read_chunks(conn, opts, acc) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, chunk, conn} ->
        body = IO.iodata_to_binary(Enum.reverse([chunk | acc]))
        conn = maybe_cache(conn, body)
        {:ok, body, conn}

      {:more, chunk, conn} ->
        read_chunks(conn, opts, [chunk | acc])

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_cache(conn, body) do
    if envelope_path?(conn.request_path) do
      Plug.Conn.put_private(conn, :babel_raw_body, body)
    else
      conn
    end
  end

  defp envelope_path?("/api/" <> rest) do
    case String.split(rest, "/", parts: 3) do
      [_project_id, "envelope", ""] -> true
      [_project_id, "envelope"] -> true
      _ -> false
    end
  end

  defp envelope_path?(_), do: false
end
