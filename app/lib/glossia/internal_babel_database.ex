defmodule Glossia.InternalBabelDatabase do
  @moduledoc """
  Executes bounded read-only PostgreSQL queries for Babel.

  The caller is already authenticated as Babel's workload identity. Every
  statement still crosses three independent safeguards: a read-only grammar
  gate, a read-only database transaction, and a least-privilege database role.
  """

  alias Glossia.Repo

  @max_rows 200
  @statement_timeout_ms 5_000

  def execute(sql, opts \\ []) do
    limit = opts |> Keyword.get(:limit, @max_rows) |> clamp_limit()

    with :ok <- validate_query(sql),
         {:ok, role} <- database_role(opts) do
      run_readonly(sql, limit, role)
    else
      {:error, :database_role_not_configured} ->
        {:error, "The read-only database role is not configured."}

      {:error, reason} when is_binary(reason) ->
        {:error, reason}
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

  defp validate_query(sql) when is_binary(sql) do
    query = sql |> String.trim() |> String.trim_trailing(";") |> String.trim()

    cond do
      query == "" ->
        {:error, "The query cannot be empty."}

      String.contains?(query, ";") ->
        {:error, "Only one statement is allowed."}

      Regex.match?(~r/\A(select|with|explain|show)\b/i, query) ->
        :ok

      true ->
        {:error, "Only SELECT, WITH, EXPLAIN, and SHOW statements are allowed."}
    end
  end

  defp validate_query(_sql), do: {:error, "The query must be a string."}

  defp clamp_limit(limit) when is_integer(limit) and limit > 0, do: min(limit, @max_rows)
  defp clamp_limit(_limit), do: @max_rows

  defp database_role(opts) do
    case Keyword.fetch(opts, :role) do
      {:ok, role} when is_binary(role) and role != "" -> {:ok, role}
      _ -> {:error, :database_role_not_configured}
    end
  end

  defp run_readonly(sql, limit, role) do
    Repo.checkout(fn ->
      result =
        Repo.transaction(fn ->
          with {:ok, _} <- Repo.query("SET TRANSACTION READ ONLY"),
               {:ok, _} <- Repo.query("SET LOCAL statement_timeout = #{@statement_timeout_ms}"),
               :ok <- set_local_role(role) do
            if cursorable?(sql) do
              fetch_via_cursor(sql, limit)
            else
              build_result(Repo.query(sql), limit)
            end
          else
            {:error, reason} -> Repo.rollback(error_message(reason))
          end
        end)

      Repo.query("SELECT pg_advisory_unlock_all()")
      result
    end)
  end

  defp set_local_role(role) when is_binary(role) do
    if Regex.match?(~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/, role) do
      case Repo.query(~s(SET LOCAL ROLE "#{role}")) do
        {:ok, _result} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :database_role_not_configured}
    end
  end

  defp set_local_role(_role), do: {:error, :database_role_not_configured}

  defp cursorable?(sql), do: Regex.match?(~r/\A\s*(select|with)\b/i, sql)

  defp fetch_via_cursor(sql, limit) do
    case Repo.query("DECLARE _babel_cursor NO SCROLL CURSOR FOR #{sql}") do
      {:ok, _result} ->
        fetched = Repo.query("FETCH FORWARD #{limit + 1} FROM _babel_cursor")
        if match?({:ok, _result}, fetched), do: Repo.query("CLOSE _babel_cursor")
        build_result(fetched, limit)

      {:error, reason} ->
        Repo.rollback(error_message(reason))
    end
  end

  defp build_result({:ok, %{columns: columns, rows: rows}}, limit) do
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

  defp build_result({:error, reason}, _limit), do: Repo.rollback(error_message(reason))

  defp error_message(%Postgrex.Error{} = error), do: Exception.message(error)
  defp error_message(error) when is_binary(error), do: error
  defp error_message(error), do: inspect(error)

  defp json_safe(nil), do: nil
  defp json_safe(value) when is_binary(value) or is_number(value) or is_boolean(value), do: value
  defp json_safe(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp json_safe(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp json_safe(%Date{} = value), do: Date.to_iso8601(value)
  defp json_safe(%Time{} = value), do: Time.to_iso8601(value)
  defp json_safe(%Decimal{} = value), do: Decimal.to_string(value)
  defp json_safe(values) when is_list(values), do: Enum.map(values, &json_safe/1)

  defp json_safe(values) when is_map(values),
    do: Map.new(values, fn {key, value} -> {to_string(key), json_safe(value)} end)

  defp json_safe(value), do: inspect(value)
end
