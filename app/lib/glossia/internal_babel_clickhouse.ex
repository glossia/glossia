defmodule Glossia.InternalBabelClickHouse do
  @moduledoc """
  Executes bounded read-only ClickHouse queries for Babel.

  The dedicated ClickHouse user profile is the security boundary: it grants
  only `SELECT` on Glossia's event database and fixes its resource limits.
  The validation below is intentionally conservative so requests that use
  side-effecting syntax and table functions fail before reaching ClickHouse.
  """

  alias Glossia.ClickHouseRepo

  @max_query_bytes 8_192
  @max_rows 200
  @query_timeout_ms 6_000
  @max_json_integer 9_007_199_254_740_991

  @restricted_patterns [
    ~r/\b(?:alter|attach|create|detach|drop|grant|insert|kill|optimize|rename|revoke|system|truncate)\b/i,
    ~r/\bsettings\b/i,
    ~r/\bformat\b/i,
    ~r/\binto\s+outfile\b/i,
    ~r/\b(?:azureblobstorage|deltalake|dictionary|dictget|executable|executablepool|file|gcs|hdfs|iceberg|jdbc|mongodb|mysql|odbc|postgresql|redis|remote|remotesecure|s3|s3cluster|url)\s*\(/i
  ]

  def execute(query, opts \\ []) do
    limit = opts |> Keyword.get(:limit, @max_rows) |> clamp_limit()

    with :ok <- validate_query(query),
         {:ok, result} <- ClickHouseRepo.query(query, [], timeout: @query_timeout_ms) do
      {:ok, build_result(result, limit)}
    else
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, _reason} -> {:error, :query_failed}
    end
  end

  def to_json_map(%{columns: columns, rows: rows} = result) do
    %{
      columns: columns,
      rows: Enum.map(rows, &json_safe/1),
      num_rows: Map.get(result, :num_rows, length(rows)),
      truncated: Map.get(result, :truncated?, false)
    }
  end

  defp validate_query(query) when is_binary(query) do
    query = normalize(query)

    cond do
      query == "" ->
        {:error, "The query cannot be empty."}

      byte_size(query) > @max_query_bytes ->
        {:error, "The query is too large."}

      String.contains?(query, ";") ->
        {:error, "Only one statement is allowed."}

      not Regex.match?(~r/\A(?:select|with|explain|show|describe)\b/i, query) ->
        {:error, "Only read-only ClickHouse statements are allowed."}

      Enum.any?(@restricted_patterns, &Regex.match?(&1, query)) ->
        {:error, "The query uses a restricted ClickHouse feature."}

      true ->
        :ok
    end
  end

  defp validate_query(_query), do: {:error, "The query must be a string."}

  defp normalize(query) do
    query
    |> String.trim_leading("\uFEFF")
    |> String.trim()
    |> String.trim_trailing(";")
    |> String.trim()
  end

  defp clamp_limit(limit) when is_integer(limit) and limit > 0, do: min(limit, @max_rows)
  defp clamp_limit(_limit), do: @max_rows

  defp build_result(%{columns: columns, rows: rows}, limit) do
    columns = columns || []

    {rows, truncated?} =
      if length(rows) > limit, do: {Enum.take(rows, limit), true}, else: {rows, false}

    %{
      columns: columns,
      rows: Enum.map(rows, &Map.new(Enum.zip(columns, &1))),
      num_rows: length(rows),
      truncated?: truncated?
    }
  end

  defp json_safe(nil), do: nil

  defp json_safe(value) when is_integer(value) and abs(value) > @max_json_integer,
    do: Integer.to_string(value)

  defp json_safe(value) when is_binary(value) or is_number(value) or is_boolean(value), do: value
  defp json_safe(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp json_safe(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp json_safe(%Date{} = value), do: Date.to_iso8601(value)
  defp json_safe(%Time{} = value), do: Time.to_iso8601(value)
  defp json_safe(%Decimal{} = value), do: Decimal.to_string(value)
  defp json_safe(values) when is_list(values), do: Enum.map(values, &json_safe/1)

  defp json_safe(values) when is_tuple(values),
    do: values |> Tuple.to_list() |> Enum.map(&json_safe/1)

  defp json_safe(values) when is_map(values),
    do: Map.new(values, fn {key, value} -> {to_string(key), json_safe(value)} end)

  defp json_safe(value), do: inspect(value)
end
