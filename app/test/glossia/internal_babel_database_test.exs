defmodule Glossia.InternalBabelDatabaseTest do
  use Glossia.DataCase, async: true

  alias Glossia.InternalBabelDatabase
  alias Glossia.Repo

  test "returns column-keyed rows for a read-only query" do
    assert {:ok, result} =
             InternalBabelDatabase.execute("SELECT 1 AS one, 'x' AS letter",
               role: database_role()
             )

    assert %{
             columns: ["one", "letter"],
             rows: [%{"one" => 1, "letter" => "x"}],
             truncated?: false
           } = result
  end

  test "rejects write statements before they reach Postgres" do
    assert {:error, "Only SELECT, WITH, EXPLAIN, and SHOW statements are allowed."} =
             InternalBabelDatabase.execute("DELETE FROM accounts", role: database_role())
  end

  test "rejects multiple statements" do
    assert {:error, "Only one statement is allowed."} =
             InternalBabelDatabase.execute("SELECT 1; SELECT 2", role: database_role())
  end

  test "the database rejects a mutating EXPLAIN statement allowed by the grammar" do
    assert {:error, error} =
             InternalBabelDatabase.execute(
               "EXPLAIN ANALYZE DELETE FROM accounts",
               role: database_role()
             )

    assert error =~ "read-only"
  end

  test "clamps returned rows to the server-side maximum" do
    assert {:ok, %{rows: rows, truncated?: true}} =
             InternalBabelDatabase.execute("SELECT generate_series(1, 1000) AS n",
               limit: 100_000,
               role: database_role()
             )

    assert length(rows) == 200
  end

  test "serializes decimal values for JSON responses" do
    assert {:ok, result} =
             InternalBabelDatabase.execute("SELECT 1.5::numeric AS amount", role: database_role())

    assert %{rows: [%{"amount" => "1.5"}]} = InternalBabelDatabase.to_json_map(result)
  end

  defp database_role do
    {:ok, %{rows: [[role]]}} = Repo.query("SELECT current_user")
    role
  end
end
