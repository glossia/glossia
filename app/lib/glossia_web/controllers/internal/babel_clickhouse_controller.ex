defmodule GlossiaWeb.Internal.BabelClickHouseController do
  @moduledoc false

  use GlossiaWeb, :controller

  alias Glossia.InternalBabelClickHouse

  def query(conn, %{"query" => query} = params) when is_binary(query) do
    opts =
      case params do
        %{"limit" => limit} when is_integer(limit) and limit > 0 -> [limit: limit]
        _ -> []
      end

    with {:ok, result} <- InternalBabelClickHouse.execute(query, opts) do
      json(conn, InternalBabelClickHouse.to_json_map(result))
    else
      {:error, reason} when is_binary(reason) ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: reason})

      {:error, :query_failed} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "query_failed"})
    end
  end

  def query(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "missing_query"})
  end
end
