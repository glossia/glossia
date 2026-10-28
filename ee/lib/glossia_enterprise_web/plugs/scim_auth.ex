defmodule GlossiaEnterpriseWeb.Plugs.SCIMAuth do
  @moduledoc false
  import Plug.Conn
  alias GlossiaEnterprise.SCIM
  alias GlossiaEnterprise.SCIM.Protocol

  def init(opts), do: opts

  def call(conn, _opts) do
    case Glossia.RateLimiter.hit(
           "scim:ip:#{GlossiaWeb.ClientIP.value(conn)}",
           :timer.minutes(1),
           300
         ) do
      {:allow, _} -> authenticate(conn)
      {:deny, retry} -> limited(conn, retry)
    end
  end

  defp authenticate(conn) do
    with [header] <- get_req_header(conn, "authorization"),
         [scheme, token] <- String.split(header, " ", parts: 2),
         true <- String.downcase(scheme) == "bearer",
         {:ok, organization} <- SCIM.authenticate_token(token) do
      case Glossia.RateLimiter.hit("scim:organization:#{organization.id}", :timer.minutes(1), 300) do
        {:allow, _} -> assign(conn, :scim_organization, organization)
        {:deny, retry} -> limited(conn, retry)
      end
    else
      _ ->
        conn
        |> put_resp_header("www-authenticate", ~s(Bearer realm="glossia-scim"))
        |> Protocol.error(401, "A valid SCIM bearer token is required")
        |> halt()
    end
  end

  defp limited(conn, retry) do
    conn
    |> put_resp_header("retry-after", to_string(ceil(retry / 1000)))
    |> Protocol.error(429, "Rate limit exceeded")
    |> halt()
  end
end
