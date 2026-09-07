defmodule GlossiaWeb.Internal.BabelClickHouseControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  @endpoint GlossiaWeb.BabelInternalEndpoint

  alias Glossia.BabelWorkloadIdentity

  setup :set_mimic_from_context

  defp authenticated(conn) do
    put_req_header(conn, "authorization", "Bearer valid-token")
  end

  defp babel_path, do: "https://babel-internal.glossia.ai/api/internal/babel/clickhouse/query"

  defp allow_babel do
    stub(BabelWorkloadIdentity, :verify, fn "valid-token" ->
      {:ok, %{namespace: "babel", name: "babel"}}
    end)
  end

  describe "POST /api/internal/babel/clickhouse/query" do
    test "returns a read-only query result", %{conn: conn} do
      allow_babel()

      conn =
        conn
        |> authenticated()
        |> post(babel_path(), %{"query" => "SELECT 1 AS one"})

      assert %{"columns" => ["one"], "rows" => [%{"one" => 1}], "truncated" => false} =
               json_response(conn, 200)
    end

    test "rejects restricted table functions", %{conn: conn} do
      allow_babel()

      conn =
        conn
        |> authenticated()
        |> post(babel_path(), %{"query" => "SELECT * FROM url('https://example.com')"})

      assert %{"error" => "The query uses a restricted ClickHouse feature."} =
               json_response(conn, 422)
    end

    test "requires a bearer token", %{conn: conn} do
      conn = post(conn, babel_path(), %{"query" => "SELECT 1"})

      assert %{"error" => "invalid_workload_identity"} = json_response(conn, 401)
    end
  end
end
