defmodule GlossiaAgent.Agent do
  @moduledoc """
  Lightweight Agent pattern for workflow orchestration with state tracking.

  An agent is a struct with typed state that can execute actions via `cmd/2`.
  Each action's result is stored in `state.result` so subsequent steps can
  read the output of previous steps.

  ## Usage

      defmodule MyAgent do
        use GlossiaAgent.Agent,
          name: "my_agent",
          description: "Orchestrates a workflow",
          schema: [
            status: [type: :atom, default: :idle],
            count: [type: :integer, default: 0]
          ]

        def run_workflow(opts) do
          agent = new(state: %{status: :running})
          {agent, _} = cmd(agent, {MyAction, %{input: "hello"}})
          result = agent.state.result
          {:ok, agent}
        end
      end
  """

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    description = Keyword.get(opts, :description, "")
    schema = Keyword.get(opts, :schema, [])

    quote do
      @agent_name unquote(name)
      @agent_description unquote(description)
      @agent_schema unquote(schema)

      defstruct [:id, :agent_module, :state]

      def name, do: @agent_name
      def description, do: @agent_description

      @doc "Create a new agent instance with optional state overrides."
      def new(opts \\ []) do
        id = Keyword.get(opts, :id, generate_id())
        state_overrides = Keyword.get(opts, :state, %{})

        default_state =
          @agent_schema
          |> Enum.reduce(%{result: nil}, fn {key, key_opts}, acc ->
            default = Keyword.get(key_opts, :default)
            Map.put(acc, key, default)
          end)

        state = Map.merge(default_state, state_overrides)

        %__MODULE__{id: id, agent_module: __MODULE__, state: state}
      end

      @doc "Update agent state fields."
      def set(%__MODULE__{} = agent, updates) when is_map(updates) do
        new_state = Map.merge(agent.state, updates)
        {:ok, %{agent | state: new_state}}
      end

      @doc """
      Execute an action and store its result in agent state.

      Returns `{updated_agent, directives}` where directives is always `[]`
      (no external effect system, kept for API compatibility).
      """
      def cmd(%__MODULE__{} = agent, action_spec) do
        {action_module, params} = normalize_action_spec(action_spec)

        case action_module.call(params) do
          {:ok, result} ->
            agent = %{agent | state: Map.put(agent.state, :result, result)}
            {agent, []}

          {:error, reason} ->
            raise "Action #{inspect(action_module)} failed: #{inspect(reason)}"
        end
      end

      defp normalize_action_spec({module, params}) when is_atom(module) and is_map(params) do
        {module, params}
      end

      defp normalize_action_spec(module) when is_atom(module) do
        {module, %{}}
      end

      defp generate_id do
        :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
      end
    end
  end
end
