defmodule GlossiaWeb.Internal.BabelDatabaseController do
  @moduledoc false

  use GlossiaWeb, :controller

  alias Glossia.BabelWorkloadIdentity
  alias Glossia.InternalBabelDatabase

  def query(conn, %{"query" => query} = params) when is_binary(query) do
    opts =
      case params do
        %{"limit" => limit} when is_integer(limit) and limit > 0 -> [limit: limit]
        _ -> []
      end

    with {:ok, role} <- BabelWorkloadIdentity.database_readonly_role(),
         {:ok, result} <- InternalBabelDatabase.execute(query, Keyword.put(opts, :role, role)) do
      json(conn, InternalBabelDatabase.to_json_map(result))
    else
      {:error, :database_role_not_configured} ->
        conn |> put_status(:service_unavailable) |> json(%{error: "database_role_not_configured"})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def query(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "missing_query"})
  end
end
