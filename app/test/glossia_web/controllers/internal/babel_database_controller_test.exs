defmodule GlossiaWeb.Internal.BabelDatabaseControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  @endpoint GlossiaWeb.BabelInternalEndpoint

  alias Glossia.BabelWorkloadIdentity
  alias Glossia.Repo

  setup :set_mimic_from_context

  defp authenticated(conn) do
    put_req_header(conn, "authorization", "Bearer valid-token")
  end

  defp babel_path, do: "https://babel-internal.glossia.ai/api/internal/babel/db/query"

  defp allow_babel do
    stub(BabelWorkloadIdentity, :verify, fn "valid-token" ->
      {:ok, %{namespace: "babel", name: "babel"}}
    end)

    stub(BabelWorkloadIdentity, :database_readonly_role, fn ->
      {:ok, database_role()}
    end)
  end

  defp database_role do
    {:ok, %{rows: [[role]]}} = Repo.query("SELECT current_user")
    role
  end

  describe "POST /api/internal/babel/db/query" do
    test "returns a read-only query result", %{conn: conn} do
      allow_babel()

      conn =
        conn
        |> authenticated()
        |> post(babel_path(), %{"query" => "SELECT 1 AS one"})

      assert %{"columns" => ["one"], "rows" => [%{"one" => 1}], "truncated" => false} =
               json_response(conn, 200)
    end

    test "rejects writes", %{conn: conn} do
      allow_babel()

      conn =
        conn
        |> authenticated()
        |> post(babel_path(), %{"query" => "DELETE FROM accounts"})

      assert %{"error" => "Only SELECT, WITH, EXPLAIN, and SHOW statements are allowed."} =
               json_response(conn, 422)
    end

    test "requires a bearer token", %{conn: conn} do
      conn =
        conn
        |> post(babel_path(), %{"query" => "SELECT 1"})

      assert %{"error" => "invalid_workload_identity"} = json_response(conn, 401)
    end
  end
end
