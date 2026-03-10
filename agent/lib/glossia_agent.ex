defmodule GlossiaAgent do
  @moduledoc """
  Glossia translation and setup agent.

  This library provides two workflows:

  - **translate/1** -- Parses GLOSSIA.md, builds a translation plan, translates
    files via LLM API calls with retry/validation, and manages lock files for
    incremental processing.

  - **setup/1** -- Analyzes a repository and generates a GLOSSIA.md configuration
    file using an LLM.

  It can run locally (as a library integrated with the Phoenix server) or
  remotely (as a Burrito-packaged executable communicating via Phoenix channels).

  Both workflows are orchestrated by Jido Agents that use Jido Actions for
  each discrete step (config parsing, plan building, file translation, etc.).
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

    * `:repo_path` - Path to the cloned repository (required)
    * `:minimax_api_key` - MiniMax API key for fallback LLM (required)
    * `:model` - LLM model name (default: "MiniMax-M2.5")
    * `:emitter` - Event emitter (required, implements `GlossiaAgent.Events.Emitter`)

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  def translate(opts) do
    case GlossiaAgent.Agents.TranslateAgent.run_workflow(opts) do
      {:ok, _agent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
