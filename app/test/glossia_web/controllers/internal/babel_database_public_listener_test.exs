defmodule GlossiaWeb.Internal.BabelDatabasePublicListenerTest do
  use GlossiaWeb.ConnCase, async: true

  test "does not expose the endpoint through the public listener", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post("http://glossia.ai:4050/api/internal/babel/db/query", %{"query" => "SELECT 1"})

    assert %{"error" => "not_found"} = json_response(conn, 404)
  end

  test "does not expose the ClickHouse endpoint through the public listener", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post("http://glossia.ai:4050/api/internal/babel/clickhouse/query", %{
        "query" => "SELECT 1"
      })

    assert %{"error" => "not_found"} = json_response(conn, 404)
  end

  test "does not expose temporary access grants through the public listener", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post("http://glossia.ai:4050/api/internal/babel/temporary-access-grants", %{
        "organization_id" => Ecto.UUID.generate(),
        "email" => "operator@glossia.ai",
        "duration_minutes" => 30,
        "requested_by_email" => "operator@glossia.ai",
        "requested_by_pomerium_id" => "google/operator",
        "reason" => "This request must not reach the public listener."
      })

    assert %{"error" => "not_found"} = json_response(conn, 404)
  end
end
