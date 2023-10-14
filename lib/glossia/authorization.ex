defmodule Glossia.Authorization do
  require Logger

  @type action :: atom | String.t()
  @type opts :: keyword | %{optional(atom) => any}

  @spec permit(policy :: module, action :: action, subject :: any, params :: any) ::
          :ok | {:error, any} | no_return()
  def permit(policy, action, subject, params \\ []) do
    params = try_to_mapify(params)

    policy
    |> apply(:authorize, [action, subject, params])
    |> resolve_result()
  end

  @spec permit!(policy :: module, action :: action, subject :: any, params :: any, opts :: opts) ::
          :ok | no_return()
  def permit!(policy, action, subject, params \\ [], opts \\ []) do
    params = try_to_mapify(params)
    opts = Enum.into(opts, %{})

    {error_message, params} =
      get_option("Glossia.Authorization!/5", params, opts, :error_message, "not authorized")

    {error_status, params} =
      get_option("Glossia.Authorization!/5", params, opts, :error_status, 403)

    case permit(policy, action, subject, params) do
      :ok ->
        :ok

      error ->
        raise Glossia.Authorization.NotAuthorizedError,
          message: error_message,
          status: error_status,
          reason: error
    end
  end

  @spec permit?(policy :: module, action :: action, subject :: any, params :: any) :: boolean
  def permit?(policy, action, subject, params \\ []) do
    case permit(policy, action, subject, params) do
      :ok -> true
      _ -> false
    end
  end

  @spec scope(query :: any, subject :: any, params :: any, opts :: opts) :: any
  def scope(query, subject, params \\ [], opts \\ []) do
    params = try_to_mapify(params)
    opts = Enum.into(opts, %{})

    {schema, params} =
      get_option_lazy("Glossia.Authorization.scope/4", params, opts, :schema, fn ->
        resolve_schema(query)
      end)

    apply(schema, :scope, [query, subject, params])
  end

  # Ecto 2 query (this feels dirty...)
  defp resolve_schema(%{__struct__: Ecto.Query, from: {_source, schema}})
       when is_atom(schema) and not is_nil(schema),
       do: schema

  # Ecto 3 query (this feels dirty...)
  defp resolve_schema(%{__struct__: Ecto.Query, from: %{source: {_source, schema}}})
       when is_atom(schema) and not is_nil(schema),
       do: schema

  # List of structs
  defp resolve_schema([%{__struct__: schema} | _rest]), do: schema

  # Schema module itself
  defp resolve_schema(schema) when is_atom(schema), do: schema

  # Unable to determine
  defp resolve_schema(unknown) do
    raise ArgumentError, "Cannot automatically determine the schema of
      #{inspect(unknown)} - specify the :schema option"
  end

  # Pulls an option from the `params` argument if possible, falling back on
  # the new `opts` argument. Returns {option_value, params}
  defp get_option_lazy(name, params, opts, key, default_fn) do
    if is_map(params) and Map.has_key?(params, key) do
      # Treat the new `params` as the old `opts`
      Logger.debug(
        "DEPRECATION WARNING - Please pass the #{inspect(key)} option to the new `opts` argument in #{name}."
      )

      Map.pop_lazy(params, key, default_fn)
    else
      # Ignore `params` and just get it from `opts`
      {Map.get_lazy(opts, key, default_fn), params}
    end
  end

  defp get_option(name, params, opts, key, default_value) do
    get_option_lazy(name, params, opts, key, fn -> default_value end)
  end

  # Attempts to convert a keyword list to a map
  defp try_to_mapify(params) do
    if Keyword.keyword?(params), do: Enum.into(params, %{}), else: params
  end

  # Coerce auth results
  defp resolve_result(true), do: :ok
  defp resolve_result(:ok), do: :ok
  defp resolve_result(false), do: {:error, default_error()}
  defp resolve_result(:error), do: {:error, default_error()}
  defp resolve_result({:error, reason}), do: {:error, reason}
  defp resolve_result(invalid), do: raise("Unexpected authorization result: #{inspect(invalid)}")
  defp default_error, do: :unauthorized
end
