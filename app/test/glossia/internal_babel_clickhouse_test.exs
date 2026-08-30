defmodule Glossia.InternalBabelClickHouseTest do
  use ExUnit.Case, async: true

  alias Glossia.InternalBabelClickHouse

  test "returns a read-only ClickHouse query result" do
    assert {:ok, result} = InternalBabelClickHouse.execute("SELECT 1 AS one")

    assert %{
             columns: ["one"],
             rows: [%{"one" => 1}],
             truncated?: false
           } = result
  end

  test "rejects statements that are not read-only" do
    assert {:error, "Only read-only ClickHouse statements are allowed."} =
             InternalBabelClickHouse.execute("INSERT INTO analytics_events VALUES (1)")
  end

  test "rejects remote table functions" do
    assert {:error, "The query uses a restricted ClickHouse feature."} =
             InternalBabelClickHouse.execute("SELECT * FROM url('https://example.com/data')")
  end

  test "rejects server-executed table functions" do
    assert {:error, "The query uses a restricted ClickHouse feature."} =
             InternalBabelClickHouse.execute(
               "SELECT * FROM executable('id', 'TSV', 'value String')"
             )
  end

  test "rejects query settings" do
    assert {:error, "The query uses a restricted ClickHouse feature."} =
             InternalBabelClickHouse.execute("SELECT 1 SETTINGS max_execution_time = 3600")
  end

  test "caps returned rows" do
    assert {:ok, %{rows: rows, truncated?: true}} =
             InternalBabelClickHouse.execute("SELECT number AS n FROM numbers(201)")

    assert length(rows) == 200
  end

  test "serializes integers outside the JSON safe range as strings" do
    result = %{
      columns: ["large_number"],
      rows: [%{"large_number" => 9_007_199_254_740_992}]
    }

    assert %{rows: [%{"large_number" => "9007199254740992"}]} =
             InternalBabelClickHouse.to_json_map(result)
  end
end
