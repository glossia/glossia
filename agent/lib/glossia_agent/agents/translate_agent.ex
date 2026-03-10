defmodule GlossiaAgent.Agents.TranslateAgent do
  @moduledoc """
  Jido Agent for the translation workflow.

  Executes a prepared translation plan by translating each source/output
  pair via LLM, writing outputs, and updating lock files for incremental
  processing.

  State tracks progress through the pipeline so callers can observe
  how many files have been processed, any errors, and the overall status.
  """

  use Jido.Agent,
    name: "translate_agent",
    description: "Orchestrates the GLOSSIA translation workflow",
    schema: [
      repo_path: [type: :string, doc: "Path to the root directory"],
      status: [type: :atom, default: :idle, doc: "Current workflow status"],
      progress: [type: :integer, default: 0, doc: "Number of pairs processed"],
      total: [type: :integer, default: 0, doc: "Total number of source/output pairs"],
      errors: [type: {:list, :any}, default: [], doc: "Accumulated errors"]
    ]

  alias GlossiaAgent.Actions
  alias GlossiaAgent.Events.Emitter
  alias GlossiaAgent.{Hash, Locks, Plan}

  @doc """
  Run the full translation workflow.

  Creates a new agent, executes the pipeline steps, and emits events
  through the provided emitter. Returns `:ok` on success or
  `{:error, reason}` on failure.
  """
  def run_workflow(opts) do
    repo_path = Keyword.fetch!(opts, :repo_path)
    translate_sources = Keyword.fetch!(opts, :translate_sources)
    total_pairs = Keyword.fetch!(opts, :total_pairs)
    emitter = Keyword.fetch!(opts, :emitter)

    {:ok, agent} = new(state: %{repo_path: repo_path, status: :planning})

    try do
      Emitter.emit(emitter, "status", "Using prepared translation plan...")

      if translate_sources == [] do
        Emitter.emit(emitter, "status", "No translation sources found in plan.")
        {:ok, agent} = set(agent, %{status: :completed})
        Emitter.complete(emitter)
        {:ok, agent}
      else
        emit_plan(emitter, translate_sources)
        {:ok, agent} = set(agent, %{status: :translating, total: total_pairs})

        agent =
          translate_all_sources(
            agent,
            translate_sources,
            repo_path,
            emitter
          )

        Emitter.emit(
          emitter,
          "status",
          "Translation complete. Processed #{agent.state.progress} file(s)."
        )

        {:ok, agent} = set(agent, %{status: :completed})
        Emitter.complete(emitter)
        {:ok, agent}
      end
    rescue
      e ->
        Emitter.fail(emitter, Exception.message(e))
        {:error, Exception.message(e)}
    end
  end

  defp emit_plan(emitter, translate_sources) do
    plan_lines =
      Enum.flat_map(translate_sources, fn source ->
        Enum.map(source.outputs, fn output ->
          "#{source.source_path} -> #{output.lang}: #{output.output_path}"
        end)
      end)

    Emitter.emit(emitter, "plan", Enum.join(plan_lines, "\n"))
  end

  defp translate_all_sources(agent, sources, repo_path, emitter) do
    Enum.reduce(sources, agent, fn source, agent ->
      translate_source(agent, source, repo_path, emitter)
    end)
  end

  defp translate_source(agent, source, repo_path, emitter) do
    source_abs_path = Path.join(repo_path, source.source_path)
    source_content = File.read!(source_abs_path)
    source_hash = Hash.hash_string(source_content)
    context_parts = source.context_bodies
    context_hash = Hash.hash_strings(context_parts)
    context = Enum.join(context_parts, "\n\n")

    Enum.reduce(source.outputs, agent, fn output, agent ->
      lang_key = Plan.Types.output_lang_key(output)
      output_abs_path = Path.join(repo_path, output.output_path)
      progress = agent.state.progress + 1
      label = "[#{progress}/#{agent.state.total}] #{source.source_path} -> #{output.lang}"

      lock = Locks.read_lock(repo_path, source.source_path)

      if lock_fresh?(lock, lang_key, source_hash, context_hash, output_abs_path) do
        Emitter.emit(emitter, "status", "Skipping #{label} (up to date)")
        {:ok, agent} = set(agent, %{progress: progress})
        agent
      else
        Emitter.emit(emitter, "status", "Translating #{label}")

        retries = if source.entry.retries != nil, do: source.entry.retries, else: 2

        {agent, _directives} =
          cmd(
            agent,
            {Actions.TranslateFile,
             %{
               source_content: source_content,
               target_lang: output.lang,
               format: source.format,
               context: context,
               preserve: source.entry.preserve,
               frontmatter: source.entry.frontmatter,
               retries: retries,
               translator: source.translator
             }}
          )

        # TranslateFile result merged: %{translated_text: ..., usage: ...}
        translated_text = agent.state.translated_text

        {agent, _directives} =
          cmd(
            agent,
            {Actions.WriteOutput,
             %{
               output_path: output_abs_path,
               content: translated_text
             }}
          )

        Emitter.emit(emitter, "status", "Wrote #{output.output_path}")

        output_hash = Hash.hash_string(translated_text)

        {agent, _directives} =
          cmd(
            agent,
            {Actions.UpdateLock,
             %{
               repo_path: repo_path,
               source_path: source.source_path,
               lang_key: lang_key,
               output_path: output.output_path,
               source_hash: source_hash,
               context_hash: context_hash,
               output_hash: output_hash
             }}
          )

        {:ok, agent} = set(agent, %{progress: progress})
        agent
      end
    end)
  end

  defp lock_fresh?(nil, _lang_key, _source_hash, _context_hash, _output_path), do: false

  defp lock_fresh?(lock, lang_key, source_hash, context_hash, output_abs_path) do
    lock_ctx_hash = Locks.lock_context_hash(lock, lang_key)
    output_entry = Map.get(lock.outputs, lang_key)

    lock.source_hash == source_hash &&
      lock_ctx_hash == context_hash &&
      output_entry != nil &&
      File.exists?(output_abs_path)
  end
end
