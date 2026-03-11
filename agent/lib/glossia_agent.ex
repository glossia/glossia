defmodule GlossiaAgent do
  @moduledoc """
  Glossia translation and setup agent.

  This library provides two workflows:

  - **translate/1** -- Parses GLOSSIA.md and builds translation sources outside
    of the runtime translation agent, then runs the agent to translate files
    via LLM API calls with validation and lock-file based incrementality.

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
    * `:minimax_api_key` - MiniMax API key for server-controlled translator (required)
    * `:model` - Server-controlled LLM model name (default: "MiniMax-M2.5")
    * `:emitter` - Event emitter (required, implements `GlossiaAgent.Events.Emitter`)

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  def translate(opts) do
    repo_path = Keyword.fetch!(opts, :repo_path)
    minimax_api_key = Keyword.fetch!(opts, :minimax_api_key)
    model = Keyword.get(opts, :model, "MiniMax-M2.5")

    server_translator =
      GlossiaAgent.Config.LLMConfig.build_server_translator(minimax_api_key, model)

    translation_sources =
      repo_path
      |> GlossiaAgent.Plan.Builder.build()
      |> apply_server_translator(server_translator)

    agent_opts =
      opts
      |> Keyword.put(:translation_sources, translation_sources)

    case GlossiaAgent.Agents.TranslateAgent.run_workflow(agent_opts) do
      {:ok, _agent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp apply_server_translator(translation_sources, server_translator) do
    Enum.map(translation_sources, fn source ->
      source_translator = source.translator || %GlossiaAgent.Config.LLMConfig.AgentConfig{}

      if String.trim(source_translator.model || "") == "" do
        %{source | translator: server_translator}
      else
        source
      end
    end)
  end
end
