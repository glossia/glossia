defmodule GlossiaWeb.Plugs.AnalyticsCorsTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Phoenix.ConnTest

  alias GlossiaWeb.Plugs.AnalyticsCors

  @opts AnalyticsCors.init([])

  test "short-circuits OPTIONS preflight with 204 and CORS headers" do
    conn = build_conn(:options, "/api/analytics/events") |> AnalyticsCors.call(@opts)

    assert conn.halted
    assert conn.status == 204
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]
    assert get_resp_header(conn, "access-control-allow-headers") == ["content-type"]
  end

  test "adds a permissive origin header to non-preflight requests without halting" do
    conn = build_conn(:post, "/api/analytics/events") |> AnalyticsCors.call(@opts)

    refute conn.halted
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end
end
