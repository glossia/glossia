defmodule GlossiaWeb.ClientIP do
  @moduledoc false

  @spec value(Plug.Conn.t()) :: String.t()
  def value(conn) do
    forwarded_for(conn) || remote_ip(conn)
  end

  defp forwarded_for(conn) do
    conn
    |> Plug.Conn.get_req_header("x-forwarded-for")
    |> List.first()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.split(",", trim: true)
        |> List.first()
        |> case do
          nil -> nil
          ip -> parse_ip(ip)
        end
    end
  end

  defp remote_ip(%Plug.Conn{remote_ip: remote_ip}) when is_tuple(remote_ip) do
    remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp remote_ip(_), do: "unknown"

  defp parse_ip(ip) when is_binary(ip) do
    candidate = String.trim(ip)

    case :inet.parse_address(String.to_charlist(candidate)) do
      {:ok, parsed} -> parsed |> :inet.ntoa() |> to_string()
      _ -> nil
    end
  end
end
