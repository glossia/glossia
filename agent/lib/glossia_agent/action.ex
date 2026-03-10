defmodule GlossiaAgent.Action do
  @moduledoc """
  Lightweight Action pattern for discrete, schema-validated workflow steps.

  An action is a module with a `run/2` callback that receives validated params
  and a context map. It declares its schema as NimbleOptions and validates
  inputs before execution.

  ## Usage

      defmodule MyAction do
        use GlossiaAgent.Action,
          name: "my_action",
          description: "Does something useful",
          schema: [
            input: [type: :string, required: true, doc: "The input value"]
          ]

        def run(params, _context) do
          {:ok, %{result: String.upcase(params.input)}}
        end
      end
  """

  @callback run(params :: map(), context :: map()) :: {:ok, map()} | {:error, term()}

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    description = Keyword.get(opts, :description, "")
    schema = Keyword.get(opts, :schema, [])

    quote do
      @behaviour GlossiaAgent.Action

      @action_name unquote(name)
      @action_description unquote(description)
      @action_schema unquote(schema)

      def name, do: @action_name
      def description, do: @action_description
      def schema, do: @action_schema

      @doc """
      Validate params against the action schema and execute `run/2`.
      """
      def call(params, context \\ %{}) do
        case validate_params(params) do
          {:ok, validated} -> run(validated, context)
          {:error, _} = error -> error
        end
      end

      defp validate_params(params) when is_map(params) do
        schema = @action_schema

        validated =
          Enum.reduce_while(schema, {:ok, %{}}, fn {key, opts}, {:ok, acc} ->
            type = Keyword.get(opts, :type, :any)
            required = Keyword.get(opts, :required, false)
            default = Keyword.get(opts, :default)

            value = Map.get(params, key)

            cond do
              value != nil ->
                {:cont, {:ok, Map.put(acc, key, value)}}

              default != nil ->
                {:cont, {:ok, Map.put(acc, key, default)}}

              required ->
                {:halt, {:error, {:missing_required, key}}}

              true ->
                {:cont, {:ok, acc}}
            end
          end)

        case validated do
          {:ok, map} ->
            extra_keys = Map.keys(params) -- Keyword.keys(schema)
            merged = Enum.reduce(extra_keys, map, &Map.put(&2, &1, Map.fetch!(params, &1)))
            {:ok, merged}

          error ->
            error
        end
      end
    end
  end
end
