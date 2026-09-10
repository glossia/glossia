defmodule Glossia.Translations.RepositoryRun do
  @moduledoc """
  Runs a repository translation natively in Elixir.

  The open-source build runs every translation in the calling process. `run/5`
  clones the repo, plans the work with `Glossia.Translations.Planner`,
  translates each stale item with `Glossia.Translations.Engine` (streaming
  every LLM turn to the translation session's PubSub topic and validating
  with `Glossia.Translations.Validate`), writes outputs and lockfiles, and
  collects the changed files via `git status`. Callers can provide an
  `:after_item_completed` callback, which receives the output and lockfile
  for the completed item after they have been written.

  `translate_repository/4` is the same orchestration without the clone, so
  it can be driven directly against a working directory in tests.
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
  @assessment_progress_interval 25
  @completed_output_preview_length 2_000
  @completed_output_preview_bytes 8_000
  # No fixed default: the fan-out follows the size of the planned work unless an
  # operator caps it explicitly. See `translation_concurrency/2`.
  @default_translation_concurrency 0
  @seq_key :translation_progress_seq

  @doc """
  Clones `repository`, translates `locales`, and returns `{:ok, changes}`.

  `changes` is a list of `%{path, status, content}` where `status` is
  `"added" | "modified" | "deleted"`, ready for the PR builder.
  """
  def run(session, account, repository, locales, run_opts \\ []) do
    with {:ok, context_snapshot} <- Context.snapshot(account) do
      run_with_context(session, account, repository, locales, context_snapshot, run_opts)
    end
  end

  defp run_with_context(session, account, repository, locales, context_snapshot, run_opts) do
    progress_node = Node.self()
    seq_start = TranslationSessions.max_progress_seq(session.id)

    opts = [
      progress_node: progress_node,
      credential_node: progress_node,
      context_node: progress_node,
      context_snapshot: context_snapshot,
      seq_start: seq_start,
      after_item_completed: Keyword.get(run_opts, :after_item_completed)
    ]

    run_here(session, account, repository, locales, opts)
  end

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

  @doc "Plans, translates, and collects changes for a checked-out repo at `repo_path`."
  def translate_repository(session, account, repo_path, locales, opts \\ []) do
    progress_node = Keyword.get(opts, :progress_node, Node.self())
    credential_node = Keyword.get(opts, :credential_node)
    context_node = Keyword.get(opts, :context_node, Node.self())
    after_item_completed = Keyword.get(opts, :after_item_completed)

    # Continues the numbering past the `run_started` that the session's move to
    # "running" already recorded, so this run's events are never mistaken for
    # ones a viewer has already folded.
    seq_counter = seed_seq(Keyword.get(opts, :seq_start, 0))

    with {:ok, context_snapshot} <- context_snapshot(account, context_node, opts),
         {:ok, items} <- build_items(repo_path, locales),
         {:ok, locale_contexts} <-
           resolve_locale_contexts(items, account, context_node, context_snapshot) do
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
        translate_prepared_items(
          prepared_items,
          session,
          account,
          repo_path,
          total,
          progress_node,
          credential_node,
          after_item_completed,
          seq_counter,
          opts
        )

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

  # Files are independent after planning: each writes a distinct localized
  # output and lockfile. Run several at once so a slow model response cannot
  # leave the rest of a repository idle. The final collection and publication
  # still happen only after every item settles, preserving one commit and one
  # pull request for the session.
  defp translate_prepared_items(
         prepared_items,
         session,
         account,
         repo_path,
         total,
         progress_node,
         credential_node,
         after_item_completed,
         seq_counter,
         opts
       ) do
    items = Enum.reject(prepared_items, &(&1.status == :up_to_date))

    case translation_concurrency(opts, length(items)) do
      1 ->
        Enum.reduce_while(items, {:ok, []}, fn prepared_item, {:ok, failures} ->
          case translate_prepared_item(
                 prepared_item,
                 session,
                 account,
                 repo_path,
                 total,
                 progress_node,
                 credential_node,
                 after_item_completed,
                 seq_counter
               ) do
            :ok ->
              {:cont, {:ok, failures}}

            {:error, failure} ->
              failures = [failure | failures]

              if stop_after_failure?(failure) do
                {:halt, {:ok, failures}}
              else
                {:cont, {:ok, failures}}
              end
          end
        end)

      concurrency ->
        translate_concurrently(
          items,
          concurrency,
          session,
          account,
          repo_path,
          total,
          progress_node,
          credential_node,
          after_item_completed,
          seq_counter
        )
    end
  end

  defp translate_concurrently(
         items,
         concurrency,
         session,
         account,
         repo_path,
         total,
         progress_node,
         credential_node,
         after_item_completed,
         seq_counter
       ) do
    {:ok, task_supervisor} = Task.Supervisor.start_link()

    translate_item = fn prepared_item ->
      translate_prepared_item(
        prepared_item,
        session,
        account,
        repo_path,
        total,
        progress_node,
        credential_node,
        after_item_completed,
        seq_counter
      )
    end

    try do
      {initial_items, queued_items} = Enum.split(items, concurrency)

      running_tasks =
        Map.new(initial_items, fn prepared_item ->
          task =
            Task.Supervisor.async_nolink(task_supervisor, fn -> translate_item.(prepared_item) end)

          {task.ref, task}
        end)

      await_translation_tasks(queued_items, running_tasks, task_supervisor, translate_item, [])
    after
      stop_translation_tasks(task_supervisor)
      Supervisor.stop(task_supervisor, :normal)
    end
  end

  defp await_translation_tasks([], running_tasks, _task_supervisor, _translate_item, failures)
       when map_size(running_tasks) == 0,
       do: {:ok, failures}

  defp await_translation_tasks(
         queued_items,
         running_tasks,
         task_supervisor,
         translate_item,
         failures
       ) do
    receive do
      {ref, result} when is_reference(ref) ->
        case Map.pop(running_tasks, ref) do
          {nil, _running_tasks} ->
            await_translation_tasks(
              queued_items,
              running_tasks,
              task_supervisor,
              translate_item,
              failures
            )

          {task, remaining_tasks} ->
            Process.demonitor(task.ref, [:flush])

            case result do
              :ok ->
                {queued_items, running_tasks} =
                  start_next_translation_task(
                    queued_items,
                    remaining_tasks,
                    task_supervisor,
                    translate_item
                  )

                await_translation_tasks(
                  queued_items,
                  running_tasks,
                  task_supervisor,
                  translate_item,
                  failures
                )

              {:error, failure} ->
                failures = [failure | failures]

                if stop_after_failure?(failure) do
                  stop_translation_tasks(task_supervisor)
                  {:ok, failures}
                else
                  {queued_items, running_tasks} =
                    start_next_translation_task(
                      queued_items,
                      remaining_tasks,
                      task_supervisor,
                      translate_item
                    )

                  await_translation_tasks(
                    queued_items,
                    running_tasks,
                    task_supervisor,
                    translate_item,
                    failures
                  )
                end
            end
        end

      {:DOWN, ref, :process, _pid, reason} when is_reference(ref) ->
        if Map.has_key?(running_tasks, ref) do
          stop_translation_tasks(task_supervisor)
          {:error, {:translation_task_failed, reason}}
        else
          await_translation_tasks(
            queued_items,
            running_tasks,
            task_supervisor,
            translate_item,
            failures
          )
        end
    end
  end

  defp start_next_translation_task([], running_tasks, _task_supervisor, _translate_item),
    do: {[], running_tasks}

  defp start_next_translation_task(
         [prepared_item | queued_items],
         running_tasks,
         task_supervisor,
         translate_item
       ) do
    task = Task.Supervisor.async_nolink(task_supervisor, fn -> translate_item.(prepared_item) end)
    {queued_items, Map.put(running_tasks, task.ref, task)}
  end

  defp stop_translation_tasks(task_supervisor) do
    task_supervisor
    |> Task.Supervisor.children()
    |> Enum.each(&Process.exit(&1, :kill))
  end

  # A provider can classify a failure as session-wide while still being
  # transient, such as a timeout or a 5xx response. Those are worth allowing
  # other files to attempt. Credit exhaustion, invalid credentials, and other
  # permanent provider responses are different: every queued item would fail
  # identically, so stop the run as soon as the first one settles.
  defp stop_after_failure?(%{reason: reason}) do
    failure = Failure.normalize(reason)
    Failure.session_level?(failure) and not Failure.retryable?(failure)
  end

  defp stop_after_failure?(_failure), do: false

  defp translate_prepared_item(
         prepared_item,
         session,
         account,
         repo_path,
         total,
         progress_node,
         credential_node,
         after_item_completed,
         seq_counter
       ) do
    # Task processes do not inherit the run's process dictionary. The atomic
    # counter gives each concurrent event a unique, monotonic sequence while
    # keeping the existing live and durable progress protocol unchanged.
    Process.put(@seq_key, seq_counter)

    # Marks the session alive between files. A translation that stops
    # heartbeating is one whose pod is gone, and that is the only signal
    # anything has that a detached run died.
    heartbeat(session, progress_node)

    apply_prepared_item(
      session,
      account,
      repo_path,
      prepared_item,
      total,
      progress_node,
      credential_node,
      after_item_completed
    )
  end

  # A configured value caps the fan-out; anything else means "as wide as the
  # work", which is what makes a run take as long as its slowest file rather
  # than as long as the sum of every file divided by a guessed constant.
  defp translation_concurrency(opts, item_count) do
    configured =
      Keyword.get(
        opts,
        :translation_concurrency,
        Application.get_env(:glossia, :translation_concurrency, @default_translation_concurrency)
      )

    ceiling = min(max(item_count, 1), http_pool_size())

    if is_integer(configured) and configured > 0,
      do: min(configured, ceiling),
      else: ceiling
  end

  # Every concurrent file holds one connection to the gateway for the length of
  # the call, so fanning out past the pool only queues the surplus until Finch
  # gives up on the checkout - which surfaces as a timeout that looks like the
  # provider's fault and is retried for nothing.
  defp http_pool_size, do: Application.get_env(:glossia, :http_pool_size, 50)

  # Plan the whole repository once (walking the filesystem and parsing the
  # L10N.md chains a single time) and filter to the requested locales in
  # memory, rather than re-planning per locale on the hot runner path.
  defp build_items(repo_path, locales) do
    case Planner.build_plan(repo_path) do
      {:ok, items} -> {:ok, filter_locales(items, locales)}
      {:error, reason} -> {:error, {:planning_failed, reason}}
    end
  end

  defp filter_locales(items, []), do: items
  defp filter_locales(items, locales), do: Enum.filter(items, &(&1.locale in locales))

  defp resolve_locale_contexts(items, account, context_node, context_snapshot) do
    locales = items |> Enum.map(& &1.locale) |> Enum.uniq()

    with {:ok, locale_contexts} <-
           Context.resolve_locales_on(context_node, account, context_snapshot, locales) do
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
          item.preserve || []
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

      output_content = if File.exists?(item.output_abs), do: File.read!(item.output_abs), else: ""

      current_output_hash =
        if output_content == "", do: "", else: Locks.output_hash(output_content)

      lock = Locks.read_lock(repo_path, item.source_path, item.locale)
      po_status = po_status_for(item.format, lock, source_content, output_content)
      item = attach_po_diff(item, po_status)

      cond do
        po_status == :fresh ->
          %{index: index, status: :up_to_date}

        Locks.stale?(lock, hash_state, item.output_path, current_output_hash) ->
          %{
            index: index,
            item: item,
            provider: provider,
            hash_state: hash_state,
            status: :translation_needed
          }

        true ->
          # Only the count is read for an up-to-date file, so its context bundle
          # is dropped here instead of being held for the whole run.
          %{index: index, status: :up_to_date}
      end
    else
      failed_item(item, index, Failure.from(:source_invalid_encoding))
    end
  end

  # `:fresh` here means the whole-file `stale?/4` check would otherwise trigger
  # (a `.pot` refresh churning references or one msgid), but per-msgid inspection
  # shows every translatable string is already up to date. Non-PO items keep the
  # whole-file behavior unchanged.
  defp po_status_for("po", lock, source_content, output_content),
    do: Locks.po_status(lock, source_content, output_content)

  defp po_status_for(_format, _lock, _source_content, _output_content), do: :not_applicable

  defp attach_po_diff(item, {:partial, diff}), do: Map.put(item, :po_diff, diff)
  defp attach_po_diff(item, _po_status), do: item

  defp failed_item(item, index, reason),
    do: %{index: index, item: item, reason: reason, status: :failed}

  defp apply_prepared_item(
         session,
         account,
         repo_path,
         %{status: :translation_needed} = prepared_item,
         total,
         progress_node,
         credential_node,
         after_item_completed
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
      credential_node,
      after_item_completed
    )
  end

  defp apply_prepared_item(
         session,
         _account,
         _repo_path,
         %{status: :failed} = prepared_item,
         total,
         progress_node,
         _credential_node,
         _after_item_completed
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

  defp context_snapshot(account, context_node, opts) do
    case Keyword.fetch(opts, :context_snapshot) do
      {:ok, snapshot} ->
        {:ok, snapshot}

      :error ->
        Context.snapshot_on(context_node, account)
    end
  end

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
         credential_node,
         after_item_completed
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

    model_calls_key = {__MODULE__, :model_calls, item.output_path}
    Process.put(model_calls_key, 0)

    on_event = fn event ->
      if event == :turn_start do
        Process.put(model_calls_key, Process.get(model_calls_key, 0) + 1)
        heartbeat(session, progress_node)
      end

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

    try do
      case Engine.apply_item(item, account, on_event, validate, engine_opts) do
        {:ok, result} ->
          write_output(item, result.text)
          write_lock(repo_path, item, provider, hash_state, result.text)

          case publish_completed_item(after_item_completed, repo_path, item) do
            :ok ->
              broadcast(
                session,
                %{
                  type: "item_completed",
                  index: index,
                  output_path: item.output_path,
                  output_preview: completed_output_preview(result.text),
                  model_calls: Process.get(model_calls_key, 0)
                },
                progress_node
              )

              :ok

            {:error, reason} ->
              failure = Failure.from({:translation_publication_failed, reason}, provider)
              log_item_failure(session, item, index, total, failure)

              broadcast(
                session,
                %{
                  type: "item_failed",
                  index: index,
                  output_path: item.output_path,
                  reason: failure,
                  model_calls: Process.get(model_calls_key, 0)
                },
                progress_node
              )

              {:error, item_failure(item, index, failure)}
          end

        {:error, reason} ->
          failure = Failure.from(reason, provider)
          log_item_failure(session, item, index, total, failure)

          broadcast(
            session,
            %{
              type: "item_failed",
              index: index,
              output_path: item.output_path,
              reason: failure,
              model_calls: Process.get(model_calls_key, 0)
            },
            progress_node
          )

          {:error, item_failure(item, index, failure)}
      end
    after
      Process.delete(model_calls_key)
    end
  end

  # Persisting the preview must stay bounded even if a model produces unusually
  # large graphemes built from combining characters. Preserve valid UTF-8 so the
  # LiveView can render the preview without a fallback path.
  defp completed_output_preview(text) do
    text
    |> take_first_bytes(@completed_output_preview_bytes)
    |> String.slice(0, @completed_output_preview_length)
  end

  defp take_first_bytes(text, limit) when byte_size(text) <= limit, do: text

  defp take_first_bytes(text, limit) do
    text
    |> binary_part(0, limit)
    |> trim_partial_codepoint()
  end

  defp trim_partial_codepoint(text) do
    if String.valid?(text) do
      text
    else
      text
      |> binary_part(0, byte_size(text) - 1)
      |> trim_partial_codepoint()
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
      "validation_code" => Map.get(failure, :validation_code),
      "validation_message" => Map.get(failure, :validation_message),
      "validation_exit_status" => Map.get(failure, :validation_exit_status),
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
        Context.provenance(item.server_context),
        po_units_for(item, text)
      )

    Locks.write_lock(repo_path, item.source_path, item.locale, lock)
  end

  # PO locks carry a per-msgid source-hash map so a later run only re-translates
  # msgids whose source strings actually changed. The map is computed from the
  # translated output because the source and output share unit keys; the output
  # is what the next run will read back to preserve unchanged msgstrs.
  defp po_units_for(%{format: "po", source_abs: source_abs}, _text) do
    case File.read(source_abs) do
      {:ok, source_content} -> Locks.po_units_map(source_content)
      _ -> nil
    end
  end

  defp po_units_for(_item, _text), do: nil

  # The local checkout remains on the source commit for the whole run, so its
  # status contains every earlier translation. Select just the current output
  # and lockfile so each publication is a small, durable checkpoint.
  defp publish_completed_item(nil, _repo_path, _item), do: :ok

  defp publish_completed_item(callback, repo_path, item) when is_function(callback, 1) do
    with {:ok, changes} <- completed_item_changes(repo_path, item) do
      case callback.(changes) do
        :ok -> :ok
        {:ok, _publication} -> :ok
        {:error, _reason} = error -> error
        other -> {:error, {:invalid_publication_result, other}}
      end
    end
  rescue
    error -> {:error, {:publication_callback_failed, Exception.message(error)}}
  end

  defp completed_item_changes(repo_path, item) do
    lock_path =
      repo_path
      |> Locks.lock_path(item.source_path, item.locale)
      |> Path.relative_to(repo_path)

    expected_paths = MapSet.new([item.output_path, lock_path])

    with {:ok, changes} <- collect_changes(repo_path) do
      changes = Enum.filter(changes, &MapSet.member?(expected_paths, &1.path))

      if changes == [] do
        {:error, :translation_change_manifest_empty}
      else
        {:ok, changes}
      end
    end
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

  defp clone(%{full_name: full_name, default_branch: default_branch} = repository) do
    dir = Path.join(System.tmp_dir!(), "glossia-translate-#{System.unique_integer([:positive])}")
    source = clone_source(full_name, repository[:token])
    branch = repository[:publication_branch] || default_branch

    case MuonTrap.cmd("git", ["clone", "--branch", branch, source, dir],
           stderr_to_stdout: true,
           into: "",
           timeout: @git_timeout_ms
         ) do
      {_output, 0} ->
        case checkout_source(dir, repository) do
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

  # A checkpointed session already has a branch containing validated outputs and
  # lockfiles. Clone it directly on a later attempt so planning skips that work
  # and publication advances the same pull request rather than opening another.
  defp checkout_source(_dir, %{publication_branch: branch})
       when is_binary(branch) and branch != "",
       do: :ok

  defp checkout_source(dir, repository), do: checkout_commit(dir, repository[:commit_sha])

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
  defp broadcast(session, event, progress_node) do
    event = Map.put(event, :seq, next_seq())

    if progress_node == node() do
      TranslationSessions.broadcast_session_event(session, event)
    else
      TranslationSessions.broadcast_session_event(session, event, progress_node)
    end
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
    case Process.get(@seq_key) do
      counter when is_reference(counter) -> :atomics.add_get(counter, 1, 1)
      _ -> 1
    end
  end

  # Seeded on the node that owns the run, which is the one with a database. A
  # FLAME runner has neither Repo nor PubSub, so it cannot look this up itself.
  defp seed_seq(seq_start) do
    counter = :atomics.new(1, [])
    :ok = :atomics.put(counter, 1, seq_start)
    Process.put(@seq_key, counter)
    counter
  end

  # Model thinking can contain thousands of free-form chunks per segment. It is
  # not part of the progress contract, so do not send it through the synchronous
  # LiveView progress channel. The surrounding segment and turn events already
  # communicate useful, stable progress.
  defp progress_events({:thinking, _chunk}), do: []
  defp progress_events(event), do: [event]

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

  defp normalize_event({:tool_call, name, id, args}),
    do: %{type: "tool_call", name: to_string(name), id: to_string(id), args: inspect(args)}

  defp normalize_event({:tool_result, id, result}),
    do: %{type: "tool_result", id: to_string(id), result: inspect(result)}

  defp normalize_event({:error, reason}),
    do: %{type: "error", reason: Failure.from({:llm_failed, reason})}

  defp normalize_event(_other), do: %{type: "unknown"}
end
