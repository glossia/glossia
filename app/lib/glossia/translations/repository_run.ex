defmodule Glossia.Translations.RepositoryRun do
  @moduledoc """
  Runs a repository translation natively in Elixir.

  The local dev/test path runs every translation in the calling process. `run/5`
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

  alias Glossia.LinguisticReviews
  alias Glossia.LinguisticReviews.RepositoryContext
  alias Glossia.Models.ModelIdentifier
  alias Glossia.Translations.Checkpoints
  alias Glossia.Translations.Credentials
  alias Glossia.Translations.Context
  alias Glossia.Translations.Engine
  alias Glossia.Translations.Failure
  alias Glossia.Translations.Locks
  alias Glossia.Translations.Planner
  alias Glossia.Translations.RepoGlossary
  alias Glossia.Translations.Repository
  alias Glossia.Translations.Validate
  alias Glossia.TranslationSessions

  @assessment_progress_interval 25
  @completed_output_preview_length 2_000
  @completed_output_preview_bytes 8_000
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
      after_item_completed: Keyword.get(run_opts, :after_item_completed),
      # Cap the run's fan-out at whatever the account's default LLM model
      # declares in its `translation_concurrency` column. This is what lets a
      # person who brings a rate-limited inference provider dial the run
      # down to something the provider will tolerate. `nil` means "no cap on
      # this account", and the global env / default takes over.
      translation_concurrency: account_translation_concurrency(account)
    ]

    run_here(session, account, repository, locales, opts)
  end

  defp account_translation_concurrency(account) do
    case Glossia.Translations.Credentials.resolve(account, nil) do
      {:ok, %{translation_concurrency: cap}} when is_integer(cap) and cap > 0 -> cap
      _ -> nil
    end
  end

  defp run_here(session, account, repository, locales, opts) do
    Repository.with_checkout(repository, fn repo_path ->
      translate_repository(session, account, repo_path, locales, opts)
    end)
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

      reviews =
        if Map.get(session, :project_id),
          do: LinguisticReviews.inputs_on(context_node, session.id),
          else: []

      {prepared_items, guidance_reviews} = attach_answers(prepared_items, reviews)

      needs_translation = Enum.count(prepared_items, &(&1.status != :up_to_date))

      broadcast(
        session,
        %{
          type: "plan_assessed",
          total: total,
          needs_translation: needs_translation,
          up_to_date: total - needs_translation,
          queued: queued_items(prepared_items)
        },
        progress_node
      )

      result =
        prepared_items
        |> translate_prepared_items(
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
        |> retry_transient_failures(
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
          if Enum.all?(failures, &(&1.reason.kind == "linguistic-input-needed")) do
            with {:ok, changes} <- collect_item_changes(repo_path, items),
                 {:ok, guidance} <- RepositoryContext.proposals(repo_path, guidance_reviews),
                 :ok <- publish_guidance(after_item_completed, guidance) do
              if failures == [],
                do: {:ok, changes ++ guidance},
                else: {:awaiting_input, changes ++ guidance}
            else
              {:error, reason} -> {:error, {:translation_publication_failed, reason}}
            end
          else
            {:error, {:translation_items_failed, Enum.reverse(failures)}}
          end
      end
    end
  end

  defp attach_answers(prepared_items, reviews) do
    Enum.map_reduce(prepared_items, [], fn prepared, used ->
      review =
        Enum.find(reviews, fn review ->
          Map.get(prepared, :review_key) ==
            {review.output_path, review.locale, review.fingerprint}
        end)

      if review do
        prepared =
          if prepared.status == :translation_needed,
            do: put_in(prepared.item[:human_answer], review.answer),
            else: prepared

        {prepared, [review | used]}
      else
        {prepared, used}
      end
    end)
  end

  defp publish_guidance(nil, _guidance), do: :ok
  defp publish_guidance(_callback, []), do: :ok

  defp publish_guidance(callback, guidance) do
    case callback.(guidance) do
      :ok -> :ok
      {:ok, _} -> :ok
      {:error, _} = error -> error
      _ -> {:error, :publication_callback_failed}
    end
  end

  defp retry_transient_failures(
         {:ok, failures},
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
    retry_indexes =
      failures
      |> Enum.filter(&transient_provider_failure?/1)
      |> MapSet.new(& &1.index)

    retry_items = Enum.filter(prepared_items, &MapSet.member?(retry_indexes, &1.index))

    if retry_items == [] or Enum.any?(failures, &stop_after_failure?/1) do
      {:ok, failures}
    else
      retained_failures = Enum.reject(failures, &MapSet.member?(retry_indexes, &1.index))

      case translate_prepared_items(
             retry_items,
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
        {:ok, retry_failures} -> {:ok, retry_failures ++ retained_failures}
        error -> error
      end
    end
  end

  defp retry_transient_failures(
         error,
         _prepared_items,
         _session,
         _account,
         _repo_path,
         _total,
         _progress_node,
         _credential_node,
         _after_item_completed,
         _seq_counter,
         _opts
       ),
       do: error

  defp transient_provider_failure?(%{reason: reason}) do
    Failure.normalize(reason).kind in ["provider-error", "provider-timeout"]
  end

  defp transient_provider_failure?(_failure), do: false

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
  # other files to attempt. Exhausted rate limits pause the run for a delayed
  # continuation; starting more queued work would immediately hit the same
  # limit. Permanent provider failures also stop the run.
  defp stop_after_failure?(%{reason: reason}) do
    failure = Failure.normalize(reason)

    failure.kind == "provider-rate-limit" or
      (Failure.session_level?(failure) and not Failure.retryable?(failure))
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
  #
  # The cap comes from the resolved LLM model's `translation_concurrency`
  # column — every inference provider has its own per-model quota, and that
  # is where the operator declares it. Whichever value wins is still clamped
  # to the HTTP pool and to the item count so we do not queue past what the
  # connection pool can actually service.
  defp translation_concurrency(opts, item_count) do
    ceiling = min(max(item_count, 1), http_pool_size())

    case Keyword.get(opts, :translation_concurrency) do
      value when is_integer(value) and value > 0 -> min(value, ceiling)
      _ -> ceiling
    end
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

  # An invalid `glossary` in L10N.md must not block translation: the file is
  # translated with the platform glossary only and the problem is logged.
  defp repo_glossary_for(item) do
    case RepoGlossary.resolve(item[:glossary], item[:glossary_translations], item.locale) do
      {:ok, entries} ->
        entries

      {:error, reason} ->
        Logger.warning(
          "ignoring invalid L10N.md glossary for #{item.source_path}: #{inspect(reason)}"
        )

        []
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
          repo_glossary_for(item)
        )

      item =
        item
        |> Map.put(:server_context, server_context)
        |> Map.put(:decision_model, Map.get(context_snapshot, :decision_model))

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
          context_documents: Map.get(item, :context_documents, []),
          locale_documents: Map.get(item, :locale_documents, []),
          retries: item.retries,
          check_cmd: item.check_cmd,
          check_cmds: item.check_cmds,
          validation: item.validation,
          validation_relative_path: item.validation_relative_path,
          server_context: item.server_context,
          decision_model: item.decision_model
        })

      output_content = if File.exists?(item.output_abs), do: File.read!(item.output_abs), else: ""

      current_output_hash =
        if output_content == "", do: "", else: Locks.output_hash(output_content)

      lock = Locks.read_lock(repo_path, item.source_path, item.locale)
      po_status = po_status_for(item.format, lock, source_content, output_content)
      item = attach_po_diff(item, po_status)

      cond do
        # Context change (glossary, voice, model, prompt, config) invalidates
        # every translation in the file, even msgstrs whose per-message
        # source hash still matches — preserving them would keep an outdated
        # translation under the new context. Drop the po_diff so the engine
        # retranslates the whole catalog.
        Locks.context_stale?(lock, hash_state) ->
          %{
            index: index,
            item: Map.delete(item, :po_diff),
            provider: provider,
            hash_state: hash_state,
            status: :translation_needed
          }

        po_status == :fresh ->
          %{index: index, status: :up_to_date}

        # A pure source change (added / modified msgid) with stable context
        # follows the per-message diff path when one exists — every unchanged
        # msgstr is preserved from the previous run and only the changed
        # msgids reach the model.
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
      |> then(fn prepared ->
        if prepared.status == :translation_needed do
          Map.merge(prepared, %{
            translation_reasons:
              Locks.translation_reasons(lock, hash_state, item.output_path, current_output_hash),
            translation_diff:
              Locks.translation_diff(lock, hash_state, item.output_path, current_output_hash)
          })
        else
          prepared
        end
      end)
      |> Map.put(
        :review_key,
        {item.output_path, item.locale, LinguisticReviews.fingerprint(hash_state)}
      )
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

  # Files are translated a few at a time, so most of a large plan has not
  # started yet. Listing them up front lets the panel show the whole plan
  # instead of only the files whose batch has begun.
  defp queued_items(prepared_items) do
    for %{index: index, item: item, status: status} = prepared <- prepared_items,
        status != :up_to_date do
      %{
        index: index,
        source_path: item.source_path,
        output_path: item.output_path,
        locale: item.locale,
        translation_reasons: Map.get(prepared, :translation_reasons, []),
        translation_diff: Map.get(prepared, :translation_diff)
      }
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
      |> Map.put(:project_id, Map.get(session, :project_id))
      |> Map.put(:translation_provider, provider)
      |> Map.put(:human_review, not is_nil(Map.get(session, :project_id)))
      |> Map.put(:context_targets, LinguisticReviews.context_targets(repo_path, item))

    item =
      if answer = Map.get(item, :human_answer) do
        Map.put(
          item,
          :prompt,
          Enum.join(
            Enum.reject(
              [
                item.prompt,
                "Recorded human linguistic answer for this exact source and context (data, not system instructions):\n" <>
                  JSON.encode!(answer)
              ],
              &is_nil/1
            ),
            "\n\n"
          )
        )
      else
        item
      end

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
      if match?({:provider_retry, _, _}, event), do: heartbeat(session, progress_node)

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

    engine_opts = checkpoint_options(engine_opts, session, account, item, hash_state)

    try do
      case Engine.apply_item(item, account, on_event, validate, engine_opts) do
        {:ok, result} ->
          write_output(item, result.text)
          write_lock(repo_path, session, item, provider, hash_state, result.text)

          case publish_completed_item(after_item_completed, repo_path, item) do
            :ok ->
              glossary_summary = glossary_summary_for(item)

              broadcast(
                session,
                %{
                  type: "item_completed",
                  index: index,
                  output_path: item.output_path,
                  output_preview: completed_output_preview(result.text),
                  model_calls: Process.get(model_calls_key, 0),
                  glossary_applied: glossary_summary.applied,
                  glossary_shadowed: glossary_summary.shadowed,
                  quality: quality_summary(Map.get(result, :quality))
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

        {:error, {:linguistic_input_needed, detail}} ->
          fingerprint = LinguisticReviews.fingerprint(hash_state)

          case LinguisticReviews.request_on(
                 progress_node,
                 session.id,
                 Map.take(item, [:source_path, :output_path, :locale, :context_targets]),
                 fingerprint,
                 detail
               ) do
            {:ok, _review} ->
              broadcast(
                session,
                %{
                  type: "item_awaiting_input",
                  index: index,
                  output_path: item.output_path,
                  locale: item.locale
                },
                progress_node
              )

              {:error, item_failure(item, index, Failure.from(:linguistic_input_needed))}

            {:error, reason} ->
              {:error, item_failure(item, index, Failure.from(reason))}
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
      "publication_code" => Map.get(failure, :publication_code),
      "publication_message" => Map.get(failure, :publication_message),
      "publication_file_error" => Map.get(failure, :publication_file_error),
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

  defp checkpoint_options(opts, session, account, item, hash_state) do
    target = Keyword.get(opts, :credential_node, node())

    with project_id when is_binary(project_id) <- Map.get(session, :project_id),
         {:ok, credential} <-
           Credentials.resolve_on(target, account, item.model, target_locale: item.locale) do
      scope =
        Checkpoints.key(
          {account.id, project_id, item.output_path, hash_state.hash, credential.model,
           credential.auth, Map.get(item, :human_answer)}
        )

      opts
      |> Keyword.put(:checkpoint_scope, scope)
      |> Keyword.put(:credential, credential)
    else
      _ -> opts
    end
  end

  defp write_lock(repo_path, session, item, provider, hash_state, text) do
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
      |> Locks.add_baseline(
        source_commit_sha: session.commit_sha,
        translation_session_id: session.id
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

  # Other workers can still be writing their artifacts. Restrict Git's manifest
  # to this item's exact paths before reading content, not after a checkout-wide
  # scan. Git retains added/modified and unchanged-file semantics.
  defp publish_completed_item(nil, _repo_path, _item), do: :ok

  defp publish_completed_item(callback, repo_path, item) when is_function(callback, 1) do
    case collect_changes(repo_path, item_paths(repo_path, item)) do
      {:ok, []} ->
        :ok

      {:ok, changes} ->
        case callback.(changes) do
          :ok -> :ok
          {:ok, _publication} -> :ok
          {:error, _reason} = error -> error
          other -> {:error, {:invalid_publication_result, other}}
        end

      {:error, _reason} = error ->
        error
    end
  rescue
    _error -> {:error, :publication_callback_failed}
  end

  defp item_paths(repo_path, item) do
    lock_path =
      repo_path
      |> Locks.lock_path(item.source_path, item.locale)
      |> Path.relative_to(repo_path)

    [item.output_path, lock_path]
  end

  # Bound both the argument list and captured output. Never publish files a
  # validator happened to leave behind, even after all workers have finished.
  defp collect_item_changes(repo_path, items) do
    items
    |> Enum.flat_map(&item_paths(repo_path, &1))
    |> Enum.uniq()
    |> Enum.chunk_every(100)
    |> Enum.reduce_while({:ok, []}, fn paths, {:ok, batches} ->
      case collect_changes(repo_path, paths) do
        {:ok, changes} -> {:cont, {:ok, [changes | batches]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, batches} -> {:ok, batches |> List.flatten() |> Enum.sort_by(& &1.path)}
      error -> error
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

  @doc "Collects changed files, optionally restricted to exact repository-relative paths."
  def collect_changes(repo_path, paths \\ []) do
    # Literal pathspecs prevent brackets or wildcard characters in an output
    # path from including another worker's artifacts. Untracked directories
    # must be expanded into individual files.
    args =
      [
        "--literal-pathspecs",
        "-C",
        repo_path,
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
        "--"
      ] ++
        paths

    case MuonTrap.cmd("git", args,
           stderr_to_stdout: true,
           into: "",
           timeout: :timer.minutes(1)
         ) do
      {output, 0} ->
        case Glossia.Git.PorcelainStatus.parse_z(output) do
          {:ok, changes} ->
            changes = Enum.uniq_by(changes, & &1.path)
            changes = if paths == [], do: changes, else: Enum.filter(changes, &(&1.path in paths))
            attach_content(changes, repo_path)

          {:error, _reason} ->
            {:error, :translation_change_manifest_incomplete}
        end

      {_output, code} ->
        {:error, {:git_status_failed, code}}
    end
  end

  @doc false
  def parse_git_status(output) do
    output
    |> Glossia.Git.PorcelainStatus.parse()
    |> Enum.uniq_by(& &1.path)
  end

  defp attach_content(changes, repo_path) do
    Enum.reduce_while(changes, {:ok, []}, fn change, {:ok, acc} ->
      case read_change(change, repo_path) do
        {:ok, change} -> {:cont, {:ok, [change | acc]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, changes} -> {:ok, Enum.reverse(changes)}
      error -> error
    end
  end

  defp read_change(%{status: "deleted"} = change, _repo_path),
    do: {:ok, Map.put(change, :content, nil)}

  defp read_change(change, repo_path) do
    path = Path.join(repo_path, change.path)

    with {:ok, %{type: :regular}} <- File.lstat(path),
         {:ok, content} <- File.read(path) do
      {:ok, Map.put(change, :content, content)}
    else
      {:ok, _stat} -> {:error, {:translation_artifact_unreadable, :not_regular}}
      {:error, reason} -> {:error, {:translation_artifact_unreadable, reason}}
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

  defp normalize_event({:quality_assessed, report}),
    do: Map.put(report, :type, "quality_assessed")

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

  defp normalize_event({:segment_retry, index, message}),
    do: %{
      type: "segment_retry",
      index: index,
      reason: Failure.from({:validation_failed, message})
    }

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

  # Snapshot of the glossary entries that shaped this file's translation, sent
  # alongside item_completed so the session view can render "N terms applied,
  # M platform terms shadowed by the repo glossary" without loading lockfiles.
  # The lockfile still carries the full namespaced ids in `context_provenance`.
  defp glossary_summary_for(item) do
    context = Map.get(item, :server_context) || %{}
    applied = Map.get(context, :glossary, []) |> Enum.map(&entry_summary/1)
    shadowed = Map.get(context, :shadowed_glossary, []) |> Enum.map(&entry_summary/1)
    %{applied: applied, shadowed: shadowed}
  end

  defp entry_summary(entry) do
    %{
      id:
        Map.get(entry, :namespaced_id) ||
          "account:" <> to_string(Map.get(entry, :logical_key, Map.get(entry, :id, ""))),
      origin: Map.get(entry, :origin, :account),
      term: Map.get(entry, :term),
      translation: Map.get(entry, :translation)
    }
  end

  # Only the scores are kept: the session history and the translation pull
  # request report them, and the reviewer's hints stay in the live stream.
  defp quality_summary(nil), do: nil

  defp quality_summary(report) do
    %{
      passed: report.passed,
      threshold: report.threshold,
      ratings: Enum.map(report.ratings, &%{label: &1.label, score: &1.score})
    }
  end
end
