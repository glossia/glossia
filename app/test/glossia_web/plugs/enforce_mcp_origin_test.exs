defmodule GlossiaWeb.Plugs.EnforceMcpOriginTest do
  use ExUnit.Case, async: false

  import Plug.Test
  import Plug.Conn, only: [put_req_header: 3]

  alias GlossiaWeb.Plugs.EnforceMcpOrigin

  setup do
    endpoint_config = Application.get_env(:glossia, GlossiaWeb.Endpoint)
    extra_origins = Application.get_env(:glossia, :mcp_extra_allowed_origins)

    Application.put_env(
      :glossia,
      GlossiaWeb.Endpoint,
      Keyword.merge(endpoint_config || [], url: [host: "glossia.example"])
    )

    on_exit(fn ->
      if endpoint_config do
        Application.put_env(:glossia, GlossiaWeb.Endpoint, endpoint_config)
      else
        Application.delete_env(:glossia, GlossiaWeb.Endpoint)
      end

      if extra_origins do
        Application.put_env(:glossia, :mcp_extra_allowed_origins, extra_origins)
      else
        Application.delete_env(:glossia, :mcp_extra_allowed_origins)
      end
    end)

    :ok
  end

  defp call_with(origin_header) do
    conn = conn(:post, "/mcp")

    conn =
      case origin_header do
        nil -> conn
        value -> put_req_header(conn, "origin", value)
      end

    EnforceMcpOrigin.call(conn, [])
  end

  test "passes requests with no Origin header (server-side clients)" do
    conn = call_with(nil)
    refute conn.halted
  end

  test "passes requests whose Origin matches the configured endpoint host" do
    conn = call_with("https://glossia.example")
    refute conn.halted
  end

  test "matches the host case-insensitively and ignores port/scheme" do
    conn = call_with("http://Glossia.Example:4000")
    refute conn.halted
  end

  test "rejects requests whose Origin host is not in the allowlist" do
    conn = call_with("https://attacker.test")
    assert conn.halted
    assert conn.status == 403
  end

  test "accepts extra allowed origins from application env" do
    Application.put_env(:glossia, :mcp_extra_allowed_origins, ["staging.glossia.example"])

    conn = call_with("https://staging.glossia.example")
    refute conn.halted
  end

  test "rejects a malformed Origin header" do
    conn = call_with("not a url")
    assert conn.halted
    assert conn.status == 403
  end
end
