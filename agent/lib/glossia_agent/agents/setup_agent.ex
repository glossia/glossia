defmodule GlossiaAgent.Agents.SetupAgent do
  @moduledoc """
  Jido Agent for the setup workflow.

  Analyzes a repository structure and generates a GLOSSIA.md configuration
  file using an LLM. Handles retry logic when the LLM output fails validation.

  State tracks the setup status and the generated GLOSSIA.md content.
  """

  use Jido.Agent,
    name: "setup_agent",
    description: "Orchestrates the GLOSSIA setup workflow",
    schema: [
      repo_path: [type: :string, doc: "Path to the root directory"],
      status: [type: :atom, default: :idle, doc: "Current workflow status"],
      result_content: [type: :string, default: "", doc: "Generated GLOSSIA.md content"]
    ]

  alias GlossiaAgent.Config
  alias GlossiaAgent.Events.Emitter
  alias GlossiaAgent.LLM
  alias GlossiaAgent.Setup

  @doc """
  Run the full setup workflow.

  Creates a new agent, analyzes the repository, and generates GLOSSIA.md.
  Returns `{:ok, glossia_md_content}` on success or `{:error, reason}` on failure.
  """
  def run_workflow(opts) do
    repo_path = Keyword.fetch!(opts, :repo_path)
    minimax_api_key = Keyword.fetch!(opts, :minimax_api_key)
    model = Keyword.get(opts, :model, "MiniMax-M2.5")
    target_languages = Keyword.get(opts, :target_languages, [])
    emitter = Keyword.fetch!(opts, :emitter)

    {:ok, agent} = new(state: %{repo_path: repo_path, status: :analyzing})
    llm_agent = Config.LLMConfig.build_fallback_agent(minimax_api_key, model)

    try do
      do_setup(agent, llm_agent, target_languages, emitter)
    rescue
      e ->
        Emitter.fail(emitter, Exception.message(e))
        {:error, Exception.message(e)}
    end
  end

  defp do_setup(agent, llm_agent, target_languages, emitter) do
    repo_path = agent.state.repo_path

    Emitter.emit(emitter, "status", "Analyzing repository structure...")
    context = Setup.RepoContext.gather(repo_path)

    if context.has_glossia_md do
      Emitter.emit(emitter, "status", "GLOSSIA.md already exists, skipping setup.")
      existing = File.read!(Path.join(repo_path, "GLOSSIA.md"))
      {:ok, _agent} = set(agent, %{status: :completed, result_content: existing})
      Emitter.complete(emitter)
      {:ok, existing}
    else
      {:ok, agent} = set(agent, %{status: :generating})
      Emitter.emit(emitter, "status", "Building setup prompt...")

      system = Setup.Prompt.system_prompt()
      user = Setup.Prompt.user_prompt(context, target_languages)
      Emitter.emit(emitter, "prompt", user)

      messages = [
        %{role: "system", content: system},
        %{role: "user", content: user}
      ]

      model_name = String.trim(llm_agent.model)
      Emitter.emit(emitter, "status", "Calling LLM (#{model_name}) to generate GLOSSIA.md...")

      result = LLM.Client.chat(llm_agent, model_name, messages)
      Emitter.emit(emitter, "text", result.text)

      case Setup.Extractor.extract(result.text) do
        {:ok, glossia_md} ->
          write_glossia_md(agent, repo_path, glossia_md, emitter)

        {:error, reason} ->
          Emitter.emit(emitter, "status", "First attempt failed: #{reason}. Retrying...")
          retry_setup(agent, llm_agent, result.text, reason, emitter)
      end
    end
  end

  defp retry_setup(agent, llm_agent, previous_output, previous_error, emitter) do
    retry_prompt = """
    Your previous output could not be parsed as a valid GLOSSIA.md file.
    Error: #{previous_error}

    Your previous output was:
    #{String.slice(previous_output, 0, 2000)}

    Please output ONLY the GLOSSIA.md file content, starting with +++ and ending \
    after the free-text context. Include at least one [[content]] entry with source, \
    targets, and output fields. No explanation, no markdown fences.
    """

    messages = [
      %{role: "system", content: Setup.Prompt.system_prompt()},
      %{role: "user", content: retry_prompt}
    ]

    model_name = String.trim(llm_agent.model)
    result = LLM.Client.chat(llm_agent, model_name, messages)

    case Setup.Extractor.extract(result.text) do
      {:ok, glossia_md} ->
        write_glossia_md(agent, agent.state.repo_path, glossia_md, emitter)

      {:error, reason} ->
        Emitter.fail(emitter, "Failed to generate valid GLOSSIA.md: #{reason}")
        {:error, reason}
    end
  end

  defp write_glossia_md(agent, repo_path, glossia_md, emitter) do
    output_path = Path.join(repo_path, "GLOSSIA.md")
    File.write!(output_path, glossia_md)
    Emitter.emit(emitter, "status", "Wrote GLOSSIA.md")
    {:ok, _agent} = set(agent, %{status: :completed, result_content: glossia_md})
    Emitter.complete(emitter)
    {:ok, glossia_md}
  end
end
