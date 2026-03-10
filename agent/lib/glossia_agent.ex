defmodule GlossiaAgent do
  @moduledoc """
  Glossia translation and setup agent.

  This library provides two workflows:

  - **translate/1** -- Parses GLOSSIA.md and builds a translation plan outside
    of the runtime translation agent, then runs the agent to translate files
    via LLM API calls with retry/validation and lock-file based incrementality.

  - **setup/1** -- Analyzes a repository and generates a GLOSSIA.md configuration
    file using an LLM.

  It can run locally (as a library integrated with the Phoenix server) or
  remotely (as a Burrito-packaged executable communicating via Phoenix channels).

  Both workflows are orchestrated by Jido Agents that use Jido Actions for
  each discrete step.
  """

  @doc """
  Run the setup workflow -- analyze a repository and generate GLOSSIA.md.

  ## Options

    * `:repo_path` - Path to the repository (required)
    * `:minimax_api_key` - MiniMax API key for LLM (required)
    * `:model` - LLM model name (default: "MiniMax-M2.5")
    * `:target_languages` - Target language codes (optional, inferred if omitted)
    * `:emitter` - Event emitter (required)

  Returns `{:ok, glossia_md_content}` on success or `{:error, reason}` on failure.
  """
  def setup(opts) do
    GlossiaAgent.Agents.SetupAgent.run_workflow(opts)
  end

  @doc """
  Run the translation workflow.

  ## Options

    * `:repo_path` - Path to the root directory (required)
    * `:minimax_api_key` - MiniMax API key for fallback LLM (required)
    * `:model` - LLM model name (default: "MiniMax-M2.5")
    * `:emitter` - Event emitter (required, implements `GlossiaAgent.Events.Emitter`)

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  def translate(opts) do
    repo_path = Keyword.fetch!(opts, :repo_path)
    minimax_api_key = Keyword.fetch!(opts, :minimax_api_key)
    model = Keyword.get(opts, :model, "MiniMax-M2.5")

    fallback_agent = GlossiaAgent.Config.LLMConfig.build_fallback_agent(minimax_api_key, model)
    plan = GlossiaAgent.Plan.Builder.build(repo_path, fallback_agent)
    translate_sources = Enum.filter(plan.sources, &(&1.kind == :translate))

    total_pairs =
      Enum.reduce(translate_sources, 0, fn source, acc ->
        acc + length(source.outputs)
      end)

    agent_opts =
      opts
      |> Keyword.put(:translate_sources, translate_sources)
      |> Keyword.put(:total_pairs, total_pairs)

    case GlossiaAgent.Agents.TranslateAgent.run_workflow(agent_opts) do
      {:ok, _agent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
