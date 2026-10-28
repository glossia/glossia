# Public-IP pinning adapted from Tuist.OAuth2.SSRFGuard, Copyright Tuist GmbH.
# SPDX-License-Identifier: FCL-1.0-MIT
# See ee/licenses/TUIST-FCL-1.0-MIT.md.
defmodule GlossiaEnterprise.Identity.OAuth2HTTP do
  @moduledoc "HTTPS-only OAuth2 requests pinned to public IPs, without redirects or retries."
  @behaviour Assent.HTTPAdapter
  alias Assent.HTTPAdapter.HTTPResponse

  def valid_url?(url) when is_binary(url) do
    case URI.new(url) do
      {:ok,
       %URI{scheme: "https", host: host, port: 443, userinfo: nil, fragment: nil, query: nil}}
      when is_binary(host) and host != "" ->
        true

      _ ->
        false
    end
  end

  def valid_url?(_), do: false

  @impl true
  def request(method, url, body, headers, opts) do
    with {:ok, pinned, host} <- pin(url, Keyword.get(opts || [], :resolver, &:inet.getaddrs/2)),
         {:ok, response} <-
           Req.request(
             method: method,
             url: pinned,
             body: body,
             headers: [{"host", host} | headers],
             decode_body: false,
             redirect: false,
             retry: false,
             receive_timeout: 10_000,
             connect_options: [
               hostname: host,
               timeout: 5_000,
               transport_opts: [
                 verify: :verify_peer,
                 cacerts: :public_key.cacerts_get(),
                 server_name_indication: String.to_charlist(host),
                 customize_hostname_check: [
                   match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
                 ]
               ]
             ]
           ) do
      {:ok,
       %HTTPResponse{
         status: response.status,
         headers:
           for({key, values} <- response.headers, value <- List.wrap(values), do: {key, value}),
         body: response.body
       }}
    end
  end

  def pin(url, resolver \\ &:inet.getaddrs/2) do
    # Resolve both families once and reject the entire hostname if any answer
    # is private. The HTTP client connects to this exact IP, preventing rebinding.
    with true <- valid_url?(url),
         %URI{host: host} = uri <- URI.parse(url) do
      addresses =
        Enum.flat_map([:inet, :inet6], fn family ->
          case resolver.(String.to_charlist(host), family) do
            {:ok, addresses} -> addresses
            _ -> []
          end
        end)

      if addresses != [] and Enum.all?(addresses, &public?/1) do
        ip = addresses |> hd() |> :inet.ntoa() |> to_string()
        {:ok, URI.to_string(%{uri | host: ip}), host}
      else
        {:error, :non_public_endpoint}
      end
    else
      _ -> {:error, :invalid_url}
    end
  end

  defp public?({a, b, c, _}) do
    a not in [0, 10, 127] and a < 224 and
      not (a == 100 and b in 64..127) and
      not (a == 169 and b == 254) and
      not (a == 172 and b in 16..31) and
      not (a == 192 and (b in [0, 168] or (b == 88 and c == 99))) and
      not (a == 198 and (b in [18, 19] or (b == 51 and c == 100))) and
      not (a == 203 and b == 0 and c == 113)
  end

  # Only global unicast IPv6; mapped IPv4, NAT64, link-local and ULA fail closed.
  defp public?({a, b, _, _, _, _, _, _}),
    do: a in 0x2000..0x3FFE and a != 0x2002 and not (a == 0x2001 and (b < 0x200 or b == 0xDB8))

  defp public?(_), do: false
end
