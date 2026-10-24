defmodule GlossiaWeb.ClientIP do
  @moduledoc """
  Resolve a client address without trusting caller-supplied forwarding chains.

  For a private ingress peer, use `X-Real-IP`, which ingress-nginx overwrites
  with its canonical address (the PROXY source on Hetzner). Never select the
  first `X-Forwarded-For` entry: a public client can supply that entry itself.
  Requests reaching the application directly use the socket peer instead.
  The proxy must derive `X-Real-IP` from PROXY protocol or a verified upstream,
  not an unrestricted caller-supplied `X-Forwarded-For` header.

  `CF-Connecting-IP` is accepted only from a private ingress peer and only
  when `:trust_cloudflare_header` is explicitly enabled in this module's
  application configuration. That requires an edge which authenticates
  Cloudflare or strips untrusted copies, not merely a Cloudflare-looking
  header. The default is false, including on DNS-only deployments.

  Private peers are the deployment's trusted ingress boundary, not proof of
  Cloudflare provenance. Restrict direct pod access to trusted workloads.
  """

  def value(conn, opts \\ Application.get_env(:glossia, __MODULE__, [])) do
    if private_peer?(conn.remote_ip) do
      cloudflare_ip(conn, opts) || header_ip(conn, "x-real-ip") || remote_ip(conn)
    else
      remote_ip(conn)
    end
  end

  defp cloudflare_ip(conn, opts) do
    if Keyword.get(opts, :trust_cloudflare_header, false) == true do
      header_ip(conn, "cf-connecting-ip")
    end
  end

  defp header_ip(conn, name) do
    case Plug.Conn.get_req_header(conn, name) do
      [value] -> parse_ip(value)
      _ -> nil
    end
  end

  defp remote_ip(%Plug.Conn{remote_ip: remote_ip}) when is_tuple(remote_ip) do
    remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp remote_ip(_), do: "unknown"

  defp parse_ip(ip) when is_binary(ip) do
    case :inet.parse_address(ip |> String.trim() |> String.to_charlist()) do
      {:ok, parsed} -> parsed |> :inet.ntoa() |> to_string()
      _ -> nil
    end
  end

  defp private_peer?({10, _, _, _}), do: true
  defp private_peer?({127, _, _, _}), do: true
  defp private_peer?({172, b, _, _}) when b in 16..31, do: true
  defp private_peer?({192, 168, _, _}), do: true
  defp private_peer?({0, 0, 0, 0, 0, 0, 0, 1}), do: true

  defp private_peer?({a, _, _, _, _, _, _, _}) when a in 0xFC00..0xFDFF, do: true

  # Bandit reports IPv4 peers as IPv4-mapped IPv6 when listening on `::`.
  defp private_peer?({0, 0, 0, 0, 0, 0xFFFF, ab, cd}) do
    private_peer?({div(ab, 256), rem(ab, 256), div(cd, 256), rem(cd, 256)})
  end

  defp private_peer?(_), do: false
end
