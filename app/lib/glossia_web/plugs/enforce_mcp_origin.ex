defmodule GlossiaWeb.Plugs.EnforceMcpOrigin do
  @moduledoc """
  Rejects MCP requests whose `Origin` header names a host outside the
  server's own origin allowlist.

  The Streamable HTTP transport in the Model Context Protocol specification
  (`2025-06-18`, "Security Warning") requires that servers validate the
  `Origin` header on all incoming HTTP requests, in order to defend against
  DNS-rebinding attacks from a browser that a local malicious site has
  duped into pointing at the MCP endpoint. Hermes 0.14.1 does not implement
  this check in its transport plug (`Hermes.Server.Transport.StreamableHTTP.Plug`),
  so we do it in the pipeline before forwarding.

  The allowlist is:

    * the configured `GlossiaWeb.Endpoint` `url[:host]`, which is the
      canonical origin of this deployment; and
    * any hosts named in `config :glossia, :mcp_extra_allowed_origins,
      [...]`, useful for regional aliases or staging domains.

  Requests without an `Origin` header (server-to-server clients like
  Claude Desktop, an MCP CLI, or a scripted probe) are allowed through —
  the DNS-rebinding attack requires the browser to attach one, so its
  absence rules the class of attack out. Requests with an `Origin` are
  compared by host (any scheme, any port), and rejected with 403 when the
  host does not match.
  """

  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case get_req_header(conn, "origin") do
      [] ->
        conn

      [origin | _] ->
        if allowed_origin?(origin) do
          conn
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            403,
            ~s({"error":"forbidden","reason":"origin_not_allowed"})
          )
          |> halt()
        end
    end
  end

  @doc "Returns the current allowlist of origin hosts."
  def allowed_hosts do
    endpoint_host =
      case Application.get_env(:glossia, GlossiaWeb.Endpoint) do
        nil ->
          nil

        endpoint_config ->
          get_in(endpoint_config, [:url, :host])
      end

    extra = Application.get_env(:glossia, :mcp_extra_allowed_origins, [])

    [endpoint_host | extra]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.uniq()
  end

  @doc false
  def allowed_origin?(origin) when is_binary(origin) do
    case URI.parse(origin) do
      %URI{host: host} when is_binary(host) ->
        String.downcase(host) in allowed_hosts()

      _ ->
        false
    end
  end

  def allowed_origin?(_), do: false
end
