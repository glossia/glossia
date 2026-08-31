defmodule Babel.Organizations.Usage do
  @moduledoc false

  alias Babel.Glossia

  def fetch(organization_id, opts \\ [])

  def fetch(nil, _opts), do: :not_connected
  def fetch("", _opts), do: :not_connected

  def fetch(organization_id, opts) when is_binary(organization_id) do
    query = Keyword.get(opts, :query, &Glossia.query/2)

    with {:ok, organization_id} <- Ecto.UUID.cast(organization_id),
         {:ok, response} <- query.(usage_query(organization_id), limit: 1),
         {:ok, usage} <- parse_usage(response) do
      {:ok, usage}
    else
      :error -> {:error, :invalid_organization_id}
      {:error, _reason} -> {:error, :unavailable}
    end
  end

  defp usage_query(organization_id) do
    """
    SELECT
      organizations.name AS organization_name,
      COUNT(DISTINCT projects.id)::integer AS project_count,
      COUNT(DISTINCT translation_sessions.id)::integer AS translation_count
    FROM organizations
    LEFT JOIN projects ON projects.account_id = organizations.account_id
    LEFT JOIN translation_sessions ON translation_sessions.account_id = organizations.account_id
    WHERE organizations.id = '#{organization_id}'::uuid
    GROUP BY organizations.name
    """
  end

  defp parse_usage(%{"rows" => [row | _]}) when is_map(row) do
    {:ok,
     %{
       organization_name: Map.get(row, "organization_name"),
       projects: count(row, "project_count"),
       translations: count(row, "translation_count")
     }}
  end

  defp parse_usage(%{"rows" => []}), do: {:error, :organization_not_found}
  defp parse_usage(_response), do: {:error, :invalid_response}

  defp count(row, key) do
    case row[key] do
      count when is_integer(count) ->
        count

      count when is_binary(count) ->
        case Integer.parse(count) do
          {parsed_count, ""} -> parsed_count
          _ -> 0
        end

      _count ->
        0
    end
  end
end
