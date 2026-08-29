defmodule GlossiaWeb.Internal.BabelDatabasePublicListenerTest do
  use GlossiaWeb.ConnCase, async: true

  test "does not expose the endpoint through the public listener", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post("http://glossia.ai:4050/api/internal/babel/db/query", %{"query" => "SELECT 1"})

    assert %{"error" => "not_found"} = json_response(conn, 404)
  end
end
