defmodule GlossiaWeb.ClientIP do
  @moduledoc """
  Resolve the real client IP address for a `Plug.Conn`.

  Precedence:

    1. `CF-Connecting-IP` — set by Cloudflare when the request came
       through an orange-clouded hostname. Trusted because
       ingress-nginx strips any inbound copy of this header (see the
       `use-forwarded-headers` + `enable-real-ip: true` block in
       `ops/infra/helm/platform/values.yaml`), so a client that
       bypasses Cloudflare cannot forge it.
    2. First hop of `X-Forwarded-For` — set by ingress-nginx from the
       socket peer.
    3. `conn.remote_ip` — the socket peer as a last resort.

  Every candidate is parsed through `:inet.parse_address/1` before it
  leaves this module so downstream Hammer keys and log lines are never
  populated with attacker-controlled strings.
  """

  @spec value(Plug.Conn.t()) :: String.t()
  def value(conn) do
    cloudflare_ip(conn) || forwarded_for(conn) || remote_ip(conn)
  end

  defp cloudflare_ip(conn) do
    conn
    |> Plug.Conn.get_req_header("cf-connecting-ip")
    |> List.first()
    |> parse_ip()
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
        |> parse_ip()
    end
  end

  defp remote_ip(%Plug.Conn{remote_ip: remote_ip}) when is_tuple(remote_ip) do
    remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp remote_ip(_), do: "unknown"

  defp parse_ip(nil), do: nil

  defp parse_ip(ip) when is_binary(ip) do
    candidate = String.trim(ip)

    case :inet.parse_address(String.to_charlist(candidate)) do
      {:ok, parsed} -> parsed |> :inet.ntoa() |> to_string()
      _ -> nil
    end
  end

  defp parse_ip(_), do: nil
end
