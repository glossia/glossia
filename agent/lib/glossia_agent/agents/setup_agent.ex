defmodule GlossiaAgent.Agents.SetupAgent do
  @moduledoc """
  Jido Agent for the setup workflow.

  Analyzes a directory structure and generates a GLOSSIA.md configuration
  file using an LLM. Handles retry logic when the LLM output fails validation.

  State tracks the setup status and the generated GLOSSIA.md content.
  """

  use Jido.Agent,
    name: "setup_agent",
    description: "Orchestrates the GLOSSIA setup workflow",
    schema: [
      directory: [type: :string, doc: "Path to the localizable directory"],
      status: [
        type: :atom,
        default: :idle,
        doc: "Current workflow status (:idle | :analyzing | :generating | :completed)"
      ],
      result_content: [type: :string, default: "", doc: "Generated GLOSSIA.md content"]
    ]

  # Jido state-machine style: keep an explicit phase in state and move it with set/2.
  # Setup status flow is: :idle -> :analyzing -> :generating -> :completed.
  alias GlossiaAgent.Events.Emitter
  alias GlossiaAgent.LLM
  alias GlossiaAgent.Setup

  @doc """
  Run the full setup workflow.

  Creates a new agent, analyzes the directory, and generates GLOSSIA.md.
  Returns `{:ok, glossia_md_content}` on success or `{:error, reason}` on failure.
  """
  def run_workflow(opts) do
    directory = Keyword.fetch!(opts, :directory)
    translator = Keyword.fetch!(opts, :translator)
    target_languages = Keyword.get(opts, :target_languages, [])
    emitter = Keyword.fetch!(opts, :emitter)

    {:ok, agent} = new(state: %{directory: directory, status: :analyzing})

    case do_setup(agent, translator, target_languages, emitter) do
      {:ok, content} ->
        {:ok, content}

      {:error, reason} ->
        Emitter.fail(emitter, reason)
        {:error, reason}
    end
  end

  defp do_setup(agent, translator, target_languages, emitter) do
    directory = agent.state.directory

    Emitter.emit(emitter, "status", "Analyzing directory structure...")
    context = Setup.RepoContext.gather(directory)

    if context.has_glossia_md do
      Emitter.emit(emitter, "status", "GLOSSIA.md already exists, skipping setup.")

      case File.read(Path.join(directory, "GLOSSIA.md")) do
        {:ok, existing} ->
          {:ok, _agent} = set(agent, %{status: :completed, result_content: existing})
          Emitter.complete(emitter)
          {:ok, existing}

        {:error, reason} ->
          {:error, "failed to read existing GLOSSIA.md: #{:file.format_error(reason)}"}
      end
    else
      with {:ok, agent} <- set(agent, %{status: :generating}),
           {:ok, result} <-
             request_setup_generation(translator, context, target_languages, emitter) do
        Emitter.emit(emitter, "text", result.text)

        case Setup.Extractor.extract(result.text) do
          {:ok, glossia_md} ->
            write_glossia_md(agent, directory, glossia_md, emitter)

          {:error, reason} ->
            Emitter.emit(emitter, "status", "First attempt failed: #{reason}. Retrying...")
            retry_setup(agent, translator, result.text, reason, emitter)
        end
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp request_setup_generation(translator, context, target_languages, emitter) do
    Emitter.emit(emitter, "status", "Building setup prompt...")

    system = Setup.Prompt.system_prompt()
    user = Setup.Prompt.user_prompt(context, target_languages)
    Emitter.emit(emitter, "prompt", user)

    messages = [
      %{role: "system", content: system},
      %{role: "user", content: user}
    ]

    model_name = String.trim(translator.model)
    Emitter.emit(emitter, "status", "Calling LLM (#{model_name}) to generate GLOSSIA.md...")

    case LLM.Client.safe_chat(translator, model_name, messages) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        {:error, "failed to generate GLOSSIA.md: #{reason}"}
    end
  end

  defp retry_setup(agent, translator, previous_output, previous_error, emitter) do
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

    model_name = String.trim(translator.model)

    with {:ok, result} <- LLM.Client.safe_chat(translator, model_name, messages) do
      case Setup.Extractor.extract(result.text) do
        {:ok, glossia_md} ->
          write_glossia_md(agent, agent.state.directory, glossia_md, emitter)

        {:error, reason} ->
          {:error, "failed to generate valid GLOSSIA.md: #{reason}"}
      end
    else
      {:error, reason} ->
        {:error, "failed to retry GLOSSIA.md generation: #{reason}"}
    end
  end

  defp write_glossia_md(agent, directory, glossia_md, emitter) do
    output_path = Path.join(directory, "GLOSSIA.md")

    case File.write(output_path, glossia_md) do
      :ok ->
        Emitter.emit(emitter, "status", "Wrote GLOSSIA.md")
        {:ok, _agent} = set(agent, %{status: :completed, result_content: glossia_md})
        Emitter.complete(emitter)
        {:ok, glossia_md}

      {:error, reason} ->
        {:error, "failed to write GLOSSIA.md: #{:file.format_error(reason)}"}
    end
  end
end
