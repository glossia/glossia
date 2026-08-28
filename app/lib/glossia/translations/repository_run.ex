defmodule Glossia.Translations.RepositoryRun do
  @moduledoc """
  Runs a repository translation natively in Elixir — no CLI.

  Where it runs depends on who is calling. Inside the detached translation Job
  the work happens in that pod directly: it is already the isolated compute, and
  placing a FLAME runner from there would re-attach the translation to a pod's
  lifetime, which is what made translations die on every deploy. Everywhere
  else — a development machine, a test — it still goes through a FLAME runner.

  `run/4` clones the repo, plans the work with
  `Glossia.Translations.Planner`, translates each stale item with
  `Glossia.Translations.Engine` (streaming every LLM turn to the translation
  session's PubSub topic and validating with `Glossia.Translations.Validate`),
  writes outputs and lockfiles, and collects the changed files via `git status`.
  The returned change list feeds the GitHub-API PR creation in
  `Glossia.TranslationSessions.Translate`.

  `translate_repository/4` is the same orchestration without the FLAME hop or the
  clone, so it can be driven directly against a working directory in tests.
  """

  require Logger

  alias Glossia.Models.ModelIdentifier
  alias Glossia.Translations.Context
  alias Glossia.Translations.Engine
  alias Glossia.Translations.Failure
  alias Glossia.Translations.Locks
  alias Glossia.Translations.Planner
  alias Glossia.Translations.Validate
  alias Glossia.TranslationSessions

  @git_timeout_ms 600_000
  @runner_timeout :infinity
  @assessment_progress_interval 25

  @doc """
  Clones `repository`, translates `locales`, and returns `{:ok, changes}`.

  `changes` is a list of `%{path, status, content}` where `status` is
  `"added" | "modified" | "deleted"`, ready for the PR builder.
  """
  def run(session, account, repository, locales, _opts \\ []) do
    with {:ok, context_snapshot} <- Context.snapshot(account, session_project(session)) do
      run_with_context(session, account, repository, locales, context_snapshot)
    end
  end

  defp run_with_context(session, account, repository, locales, context_snapshot) do
    progress_node = Node.self()
    seq_start = TranslationSessions.max_progress_seq(session.id)

    opts = [
      progress_node: progress_node,
      credential_node: progress_node,
      context_node: progress_node,
      context_snapshot: context_snapshot,
      seq_start: seq_start
    ]

    if Glossia.TranslationSessions.Job.current?() do
      run_here(session, account, repository, locales, opts)
    else
      run_in_flame(session, account, repository, locales, opts)
    end
  end

  # A detached translation pod is already the isolated compute: it has no FLAME
  # pool to place work onto, and adding one would recreate the ownership that
  # made translations die with the pod that started them.
  defp run_here(session, account, repository, locales, opts) do
    case clone(repository) do
      {:ok, repo_path} ->
        try do
          translate_repository(session, account, repo_path, locales, opts)
        after
          File.rm_rf(repo_path)
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp run_in_flame(session, account, repository, locales, opts) do
    caller = self()
    result_ref = make_ref()

    {runner_pid, monitor_ref} =
      spawn_monitor(fn ->
        result =
          FLAME.call(
            Glossia.Flame.pool_name(),
            fn ->
              case clone(repository) do
                {:ok, repo_path} ->
                  try do
                    translate_repository(session, account, repo_path, locales, opts)
                  after
                    File.rm_rf(repo_path)
                  end

                {:error, _reason} = error ->
                  error
              end
            end,
            timeout: @runner_timeout
          )

        send(caller, {result_ref, result})
      end)

    receive do
      {^result_ref, result} ->
        Process.demonitor(monitor_ref, [:flush])
        result

      {:DOWN, ^monitor_ref, :process, ^runner_pid, reason} ->
        {:error, {:runner_exit, reason}}
    after
      @runner_timeout ->
        Process.exit(runner_pid, :kill)
        Process.demonitor(monitor_ref, [:flush])
        {:error, :runner_timeout}
    end
  end

  @doc "Plans, translates, and collects changes for a checked-out repo at `repo_path`."
  def translate_repository(session, account, repo_path, locales, opts \\ []) do
    progress_node = Keyword.get(opts, :progress_node, Node.self())
    credential_node = Keyword.get(opts, :credential_node)
    context_node = Keyword.get(opts, :context_node, Node.self())

    # Continues the numbering past the `run_started` that the session's move to
    # "running" already recorded, so this run's events are never mistaken for
    # ones a viewer has already folded.
    seed_seq(Keyword.get(opts, :seq_start, 0))

    project = session_project(session)

    with {:ok, context_snapshot} <- context_snapshot(account, project, context_node, opts),
         {:ok, items} <- build_items(repo_path, locales),
         {:ok, locale_contexts} <-
           resolve_locale_contexts(items, account, project, context_node, context_snapshot) do
      total = length(items)
      broadcast(session, %{type: "plan", total: total}, progress_node)

      prepared_items =
        prepare_items(session, repo_path, items, context_snapshot, locale_contexts, progress_node)

      needs_translation = Enum.count(prepared_items, &(&1.status != :up_to_date))

      broadcast(
        session,
        %{
          type: "plan_assessed",
          total: total,
          needs_translation: needs_translation,
          up_to_date: total - needs_translation
        },
        progress_node
      )

      result =
        prepared_items
        |> Enum.reject(&(&1.status == :up_to_date))
        |> Enum.reduce_while({:ok, []}, fn prepared_item, {:ok, failures} ->
          # Marks the session alive between files. A translation that stops
          # heartbeating is one whose pod is gone, and that is the only signal
          # anything has that a detached run died.
          heartbeat(session, progress_node)

          case apply_prepared_item(
                 session,
                 account,
                 repo_path,
                 prepared_item,
                 total,
                 progress_node,
                 credential_node
               ) do
            :ok -> {:cont, {:ok, failures}}
            {:error, failure} -> {:cont, {:ok, [failure | failures]}}
          end
        end)

      case result do
        {:ok, failures} ->
          case Enum.reverse(failures) do
            [] ->
              collect_changes(repo_path)

            failures ->
              {:error, {:translation_items_failed, failures}}
          end
      end
    end
  end

  # Plan the whole repository once (walking the filesystem and parsing the
  # GLOSSIA.md chains a single time) and filter to the requested locales in
  # memory, rather than re-planning per locale on the hot runner path.
  defp build_items(repo_path, locales) do
    case Planner.build_plan(repo_path) do
      {:ok, items} -> {:ok, filter_locales(items, locales)}
      {:error, reason} -> {:error, {:planning_failed, reason}}
    end
  end

  defp filter_locales(items, []), do: items
  defp filter_locales(items, locales), do: Enum.filter(items, &(&1.locale in locales))

  defp resolve_locale_contexts(items, account, project, context_node, context_snapshot) do
    locales = items |> Enum.map(& &1.locale) |> Enum.uniq()

    with {:ok, locale_contexts} <-
           Context.resolve_locales_on(
             context_node,
             account,
             project,
             context_snapshot,
             locales
           ) do
      {:ok, Context.prepare_locale_contexts(locale_contexts)}
    end
  end

  # Resolving an item's lock state means building its context bundle, which is
  # the expensive half of the assessment. A repository whose files are almost
  # all up to date therefore spends most of the run here, so report how far the
  # assessment has come rather than leaving the session silent until it ends.
  defp prepare_items(session, repo_path, items, context_snapshot, locale_contexts, progress_node) do
    total = length(items)

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      prepared = prepare_item(repo_path, item, index, context_snapshot, locale_contexts)
      broadcast_assessment_progress(session, index + 1, total, progress_node)
      prepared
    end)
  end

  defp broadcast_assessment_progress(session, checked, total, progress_node) do
    if checked < total and rem(checked, @assessment_progress_interval) == 0 do
      broadcast(
        session,
        %{type: "plan_progress", checked: checked, total: total},
        progress_node
      )
    end

    :ok
  end

  defp prepare_item(repo_path, item, index, context_snapshot, locale_contexts) do
    case File.read(item.source_abs) do
      {:ok, source_content} ->
        prepare_readable_item(
          repo_path,
          item,
          index,
          source_content,
          context_snapshot,
          locale_contexts
        )

      {:error, reason} ->
        failed_item(item, index, Failure.from({:source_unreadable, reason}))
    end
  end

  defp prepare_readable_item(
         repo_path,
         item,
         index,
         source_content,
         context_snapshot,
         locale_contexts
       ) do
    if String.valid?(source_content) do
      {_preserved_frontmatter, translatable_source} = Engine.prepare(item, source_content)

      server_context =
        Context.build_bundle(
          context_snapshot,
          locale_contexts,
          item.locale,
          translatable_source,
          item.preserve || [],
          item.source_path
        )

      item = Map.put(item, :server_context, server_context)
      provider = ModelIdentifier.provider(item.model)

      hash_state =
        Locks.build_hash_state(%{
          format: item.format,
          source_path: item.source_path,
          source_content: source_content,
          provider: provider,
          model: item.model || "",
          source_language: item.source_language,
          language: item.language,
          locale: item.locale,
          frontmatter_mode: item.frontmatter_mode,
          preserve: item.preserve || [],
          custom_prompt: item.prompt,
          context_body: item.context_body,
          locale_override_body: item.locale_override_body,
          retries: item.retries,
          check_cmd: item.check_cmd,
          check_cmds: item.check_cmds,
          validation: item.validation,
          validation_relative_path: item.validation_relative_path,
          server_context: item.server_context
        })

      current_output_hash =
        if File.exists?(item.output_abs),
          do: Locks.output_hash(File.read!(item.output_abs)),
          else: ""

      lock = Locks.read_lock(repo_path, item.source_path, item.locale)

      if Locks.stale?(lock, hash_state, item.output_path, current_output_hash) do
        %{
          index: index,
          item: item,
          provider: provider,
          hash_state: hash_state,
          status: :translation_needed
        }
      else
        # Only the count is read for an up-to-date file, so its context bundle
        # is dropped here instead of being held for the whole run.
        %{index: index, status: :up_to_date}
      end
    else
      failed_item(item, index, Failure.from(:source_invalid_encoding))
    end
  end

  defp failed_item(item, index, reason),
    do: %{index: index, item: item, reason: reason, status: :failed}

  defp apply_prepared_item(
         session,
         account,
         repo_path,
         %{status: :translation_needed} = prepared_item,
         total,
         progress_node,
         credential_node
       ) do
    translate_item(
      session,
      account,
      repo_path,
      prepared_item.item,
      prepared_item.index,
      total,
      prepared_item.provider,
      prepared_item.hash_state,
      progress_node,
      credential_node
    )
  end

  defp apply_prepared_item(
         session,
         _account,
         _repo_path,
         %{status: :failed} = prepared_item,
         total,
         progress_node,
         _credential_node
       ) do
    log_item_failure(
      session,
      prepared_item.item,
      prepared_item.index,
      total,
      prepared_item.reason
    )

    broadcast(
      session,
      %{
        type: "item_failed",
        index: prepared_item.index,
        total: total,
        output_path: prepared_item.item.output_path,
        reason: prepared_item.reason
      },
      progress_node
    )

    {:error, item_failure(prepared_item.item, prepared_item.index, prepared_item.reason)}
  end

  defp context_snapshot(account, project, context_node, opts) do
    case Keyword.fetch(opts, :context_snapshot) do
      {:ok, snapshot} ->
        {:ok, snapshot}

      :error ->
        Context.snapshot_on(context_node, account, project)
    end
  end

  defp session_project(%{project: %Glossia.Accounts.Project{} = project}), do: project
  defp session_project(_session), do: nil

  defp translate_item(
         session,
         account,
         repo_path,
         item,
         index,
         total,
         provider,
         hash_state,
         progress_node,
         credential_node
       ) do
    item =
      item
      |> Map.put(:translation_session_id, session.id)
      |> Map.put(:translation_provider, provider)

    broadcast(
      session,
      %{
        type: "item_started",
        index: index,
        total: total,
        output_path: item.output_path,
        locale: item.locale
      },
      progress_node
    )

    reset_thinking_buffer()

    on_event = fn event ->
      Enum.each(progress_events(event), fn emitted ->
        broadcast(
          session,
          %{
            type: "item_event",
            index: index,
            output_path: item.output_path,
            event: normalize_event(emitted)
          },
          progress_node
        )
      end)
    end

    validate = fn output, source ->
      Validate.validate_output(
        repo_path,
        item.format,
        output,
        source,
        validate_opts(repo_path, item)
      )
    end

    engine_opts =
      if is_nil(credential_node), do: [], else: [credential_node: credential_node]

    case Engine.apply_item(item, account, on_event, validate, engine_opts) do
      {:ok, result} ->
        write_output(item, result.text)
        write_lock(repo_path, item, provider, hash_state, result.text)

        broadcast(
          session,
          %{
            type: "item_completed",
            index: index,
            output_path: item.output_path
          },
          progress_node
        )

        :ok

      {:error, reason} ->
        failure = Failure.from(reason, provider)
        log_item_failure(session, item, index, total, failure)

        broadcast(
          session,
          %{
            type: "item_failed",
            index: index,
            output_path: item.output_path,
            reason: failure
          },
          progress_node
        )

        {:error, item_failure(item, index, failure)}
    end
  end

  defp item_failure(item, index, reason) do
    %{
      index: index,
      output_path: item.output_path,
      locale: item.locale,
      reason: reason,
      diagnostics: %{
        source_path: item.source_path,
        format: item.format,
        frontmatter_mode: item.frontmatter_mode,
        model: item.model,
        provider: Map.get(item, :translation_provider)
      }
    }
  end

  # Record one safe, queryable log entry per item. The session-level error only
  # tells operators that a run failed; this ties it to a path, locale, format,
  # model, and provider without leaking translated content or provider payloads.
  defp log_item_failure(session, item, index, total, failure) do
    details = %{
      "event" => "translation.item_failed",
      "translation_session_id" => session.id,
      "item_index" => index,
      "item_total" => total,
      "source_path" => item.source_path,
      "output_path" => item.output_path,
      "locale" => item.locale,
      "format" => item.format,
      "frontmatter_mode" => to_string(item.frontmatter_mode),
      "model" => item.model,
      "provider" => failure.provider || Map.get(item, :translation_provider),
      "failure_kind" => failure.kind,
      "failure_scope" => failure.scope,
      "provider_status" => failure.status,
      "provider_error_code" => failure.code,
      "provider_request_id" => failure.request_id
    }

    Logger.error("Translation item failed: #{JSON.encode!(details)}")
  end

  defp write_output(item, text) do
    File.mkdir_p!(Path.dirname(item.output_abs))
    File.write!(item.output_abs, text)
  end

  defp write_lock(repo_path, item, provider, hash_state, text) do
    lock =
      Locks.build_lock(
        provider,
        item.model || "",
        item.source_path,
        item.output_path,
        text,
        hash_state.hash,
        hash_state.tree,
        Context.provenance(item.server_context)
      )

    Locks.write_lock(repo_path, item.source_path, item.locale, lock)
  end

  defp validate_opts(repo_path, item) do
    %{
      preserve: item.preserve,
      check_cmd: item.check_cmd,
      check_cmds: item.check_cmds,
      validation: item.validation,
      validation_cwd: validation_cwd(repo_path, item.validation_relative_path),
      validation_doc_abs:
        item.validation_relative_path && Path.join(repo_path, item.validation_relative_path),
      source_abs: item.source_abs,
      target_abs: item.output_abs,
      locale: item.locale
    }
  end

  defp validation_cwd(_repo_path, nil), do: nil

  defp validation_cwd(repo_path, relative_path),
    do: Path.dirname(Path.join(repo_path, relative_path))

  # ── change collection (git status) ────────────────────────────────────────

  @doc "Collects changed files under `repo_path` as `%{path, status, content}`."
  def collect_changes(repo_path) do
    # `--untracked-files=all` lists new files individually instead of collapsing
    # untracked directories (e.g. `docs/i18n/`, `.glossia/`) into a single entry.
    #
    case MuonTrap.cmd(
           "git",
           ["-C", repo_path, "status", "--porcelain", "--untracked-files=all"],
           stderr_to_stdout: true,
           into: "",
           timeout: :timer.minutes(1)
         ) do
      {output, 0} -> {:ok, output |> parse_git_status() |> attach_content(repo_path)}
      {output, code} -> {:error, {:git_status_failed, code, String.trim(output)}}
    end
  end

  @doc false
  def parse_git_status(output) do
    output
    |> Glossia.Git.PorcelainStatus.parse()
    |> Enum.uniq_by(& &1.path)
  end

  defp attach_content(changes, repo_path) do
    Enum.map(changes, fn
      %{status: "deleted"} = change -> Map.put(change, :content, nil)
      change -> Map.put(change, :content, File.read!(Path.join(repo_path, change.path)))
    end)
  end

  # ── clone ─────────────────────────────────────────────────────────────────

  defp clone(%{full_name: full_name, default_branch: branch} = repository) do
    dir = Path.join(System.tmp_dir!(), "glossia-translate-#{System.unique_integer([:positive])}")
    source = clone_source(full_name, repository[:token])

    case MuonTrap.cmd("git", ["clone", "--branch", branch, source, dir],
           stderr_to_stdout: true,
           into: "",
           timeout: @git_timeout_ms
         ) do
      {_output, 0} ->
        case checkout_commit(dir, repository[:commit_sha]) do
          :ok ->
            {:ok, dir}

          {:error, _reason} = error ->
            File.rm_rf(dir)
            error
        end

      {output, _code} ->
        {:error, {:clone_failed, String.trim(output)}}
    end
  end

  # In development a `local_remotes_dir` can hold seeded repositories that stand in
  # for GitHub remotes (see `priv/repo/seeds.exs`); clone from there when present,
  # otherwise from GitHub over HTTPS with the installation token.
  defp clone_source(full_name, token) do
    case local_remote_path(full_name) do
      {:ok, path} -> path
      :none -> "https://x-access-token:#{token}@github.com/#{full_name}.git"
    end
  end

  defp local_remote_path(full_name) do
    with dir when is_binary(dir) and dir != "" <-
           Application.get_env(:glossia, Glossia.Translations, [])[:local_remotes_dir],
         path <- Path.join(Path.expand(dir), full_name),
         true <- File.dir?(path) do
      {:ok, path}
    else
      _ -> :none
    end
  end

  defp checkout_commit(_dir, sha) when sha in [nil, ""], do: :ok

  defp checkout_commit(dir, sha) do
    case MuonTrap.cmd("git", ["-C", dir, "checkout", sha],
           stderr_to_stdout: true,
           into: "",
           timeout: :timer.minutes(1)
         ) do
      {_output, 0} -> :ok
      {output, code} -> {:error, {:checkout_failed, sha, code, String.trim(output)}}
    end
  end

  # ── helpers ─────────────────────────────────────────────────────────────

  # Every event is stamped with a sequence that keeps climbing for the lifetime
  # of the session, seeded from what is already persisted so a second attempt
  # continues the numbering rather than restarting it. A viewer folding the
  # persisted prefix and the live stream together uses it to ignore what it has
  # already applied.
  @seq_key :translation_progress_seq

  defp broadcast(session, event, progress_node) do
    event = Map.put(event, :seq, next_seq())
    TranslationSessions.broadcast_session_event(session, event, progress_node)
  end

  # Written on the node with a database, which is this one for a detached
  # translation and the placing node for a FLAME runner.
  defp heartbeat(session, progress_node) when progress_node == node(),
    do: TranslationSessions.heartbeat_session(session.id)

  defp heartbeat(session, progress_node) do
    :rpc.cast(progress_node, TranslationSessions, :heartbeat_session, [session.id])
    :ok
  end

  defp next_seq do
    seq = (Process.get(@seq_key) || 0) + 1
    Process.put(@seq_key, seq)
    seq
  end

  # Seeded on the node that owns the run, which is the one with a database. A
  # FLAME runner has neither Repo nor PubSub, so it cannot look this up itself.
  defp seed_seq(seq_start), do: Process.put(@seq_key, seq_start)

  # A reasoning model streams several thousand thinking chunks per segment, and
  # every progress event is a synchronous call to the node serving the LiveView.
  # Thinking is coalesced into one event per @thinking_flush_ms so the reasoning
  # preview still moves without the progress channel becoming the slowest part
  # of a translation. Items run one at a time in this process, and the buffer is
  # reset for each, so it never carries reasoning across files.
  @thinking_flush_ms 250
  @thinking_buffer_key :translation_thinking_buffer

  defp reset_thinking_buffer,
    do: Process.put(@thinking_buffer_key, {"", System.monotonic_time(:millisecond)})

  defp progress_events({:thinking, chunk}) when is_binary(chunk) do
    {buffered, flushed_at} = thinking_buffer()
    buffered = buffered <> chunk
    now = System.monotonic_time(:millisecond)

    if now - flushed_at >= @thinking_flush_ms do
      Process.put(@thinking_buffer_key, {"", now})
      [{:thinking, buffered}]
    else
      Process.put(@thinking_buffer_key, {buffered, flushed_at})
      []
    end
  end

  # Anything else flushes first, so the reasoning a viewer reads stays in the
  # order the model produced it.
  defp progress_events(event) do
    case thinking_buffer() do
      {"", _flushed_at} ->
        [event]

      {buffered, _flushed_at} ->
        Process.put(@thinking_buffer_key, {"", System.monotonic_time(:millisecond)})
        [{:thinking, buffered}, event]
    end
  end

  defp thinking_buffer,
    do: Process.get(@thinking_buffer_key, {"", System.monotonic_time(:millisecond)})

  defp normalize_event(:agent_start), do: %{type: "agent_start"}
  defp normalize_event(:agent_end), do: %{type: "agent_end"}
  defp normalize_event(:turn_start), do: %{type: "turn_start"}
  defp normalize_event(:turn_end), do: %{type: "turn_end"}
  defp normalize_event(:done), do: %{type: "done"}
  defp normalize_event({:attempt_start, attempt}), do: %{type: "attempt_start", attempt: attempt}

  defp normalize_event({:provider_retry, attempt, max_attempts}),
    do: %{type: "provider_retry", attempt: attempt, max_attempts: max_attempts}

  defp normalize_event({:context_budget, budget}),
    do: Map.put(budget, :type, "context_budget")

  defp normalize_event({:segment_start, index, count, kind}),
    do: %{type: "segment_start", index: index, count: count, kind: to_string(kind)}

  defp normalize_event({:segment_retry, index, _message}),
    do: %{type: "segment_retry", index: index}

  defp normalize_event({:segment_output, text}), do: %{type: "segment_output", text: text}
  defp normalize_event({:translation_output, text}), do: %{type: "translation_output", text: text}

  defp normalize_event({:validation_error, reason}),
    do: %{type: "validation_error", reason: Failure.from({:validation_failed, reason})}

  defp normalize_event({:text, chunk}), do: %{type: "text", text: chunk}
  defp normalize_event({:thinking, chunk}), do: %{type: "thinking", text: chunk}

  defp normalize_event({:tool_call, name, id, args}),
    do: %{type: "tool_call", name: to_string(name), id: to_string(id), args: inspect(args)}

  defp normalize_event({:tool_result, id, result}),
    do: %{type: "tool_result", id: to_string(id), result: inspect(result)}

  defp normalize_event({:error, reason}),
    do: %{type: "error", reason: Failure.from({:llm_failed, reason})}

  defp normalize_event(_other), do: %{type: "unknown"}
end
