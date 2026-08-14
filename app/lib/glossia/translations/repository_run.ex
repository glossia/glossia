defmodule Glossia.Translations.RepositoryRun do
  @moduledoc """
  Runs a repository translation natively in Elixir inside a FLAME runner — no CLI.

  `run/4` clones the repo into a runner, plans the work with
  `Glossia.Translations.Planner`, translates each stale item with
  `Glossia.Translations.Engine` (streaming every LLM turn to the translation
  session's PubSub topic and validating with `Glossia.Translations.Validate`),
  writes outputs and lockfiles, and collects the changed files via `git status`.
  The returned change list feeds the GitHub-API PR creation in
  `Glossia.TranslationSessions.Translate`.

  `translate_repository/4` is the same orchestration without the FLAME hop or the
  clone, so it can be driven directly against a working directory in tests.
  """

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

  @doc """
  Clones `repository`, translates `locales`, and returns `{:ok, changes}`.

  `changes` is a list of `%{path, status, content}` where `status` is
  `"added" | "modified" | "deleted"`, ready for the PR builder.
  """
  def run(session, account, repository, locales, opts \\ []) do
    with {:ok, context_snapshot} <- Context.snapshot(account) do
      run_with_context(session, account, repository, locales, context_snapshot, opts)
    end
  end

  defp run_with_context(session, account, repository, locales, context_snapshot, opts) do
    progress_node = Node.self()
    publication_target = Keyword.get(opts, :publication_target)
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
                    translate_repository(session, account, repo_path, locales,
                      progress_node: progress_node,
                      credential_node: progress_node,
                      context_node: progress_node,
                      context_snapshot: context_snapshot,
                      publication_target: publication_target
                    )
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
    publication_target = Keyword.get(opts, :publication_target)

    with {:ok, context_snapshot} <- context_snapshot(account, context_node, opts),
         {:ok, items} <- build_items(repo_path, locales),
         {:ok, locale_contexts} <-
           resolve_locale_contexts(items, account, context_node, context_snapshot) do
      total = length(items)
      broadcast(session, %{type: "plan", total: total}, progress_node)

      result =
        items
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {item, index}, {:ok, failures} ->
          case apply_one(
                 session,
                 account,
                 repo_path,
                 item,
                 index,
                 total,
                 progress_node,
                 credential_node,
                 context_snapshot,
                 locale_contexts,
                 publication_target
               ) do
            :ok -> {:cont, {:ok, failures}}
            {:error, failure} -> {:cont, {:ok, [failure | failures]}}
            {:publication_error, reason} -> {:halt, {:publication_error, reason}}
          end
        end)

      case result do
        {:publication_error, reason} ->
          {:error, {:translation_publication_failed, reason}}

        {:ok, failures} ->
          case Enum.reverse(failures) do
            [] -> collect_changes(repo_path)
            failures -> {:error, {:translation_items_failed, failures}}
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

  defp resolve_locale_contexts(items, account, context_node, context_snapshot) do
    locales = items |> Enum.map(& &1.locale) |> Enum.uniq()

    with {:ok, locale_contexts} <-
           Context.resolve_locales_on(context_node, account, context_snapshot, locales) do
      {:ok, Context.prepare_locale_contexts(locale_contexts)}
    end
  end

  defp apply_one(
         session,
         account,
         repo_path,
         item,
         index,
         total,
         progress_node,
         credential_node,
         context_snapshot,
         locale_contexts,
         publication_target
       ) do
    source_content = File.read!(item.source_abs)

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

      translate_or_skip_item(
        session,
        account,
        repo_path,
        item,
        source_content,
        index,
        total,
        progress_node,
        credential_node,
        publication_target
      )
    else
      failure = Failure.from(:source_invalid_encoding)

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

  defp translate_or_skip_item(
         session,
         account,
         repo_path,
         item,
         source_content,
         index,
         total,
         progress_node,
         credential_node,
         publication_target
       ) do
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

    if Locks.stale?(lock, hash_state.hash, item.output_path, current_output_hash) do
      translate_item(
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
        publication_target
      )
    else
      broadcast(
        session,
        %{type: "item_skipped", index: index, output_path: item.output_path},
        progress_node
      )

      :ok
    end
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
         publication_target
       ) do
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

    on_event = fn event ->
      broadcast(
        session,
        %{
          type: "item_event",
          index: index,
          output_path: item.output_path,
          event: normalize_event(event)
        },
        progress_node
      )
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

        case publish_item(repo_path, item, publication_target) do
          {:ok, publication} ->
            broadcast(
              session,
              %{
                type: "item_completed",
                index: index,
                output_path: item.output_path,
                file_ref: publication[:ref]
              },
              progress_node
            )

            :ok

          {:error, reason} ->
            {:publication_error, reason}
        end

      {:error, reason} ->
        failure = Failure.from(reason, provider)

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
      reason: reason
    }
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

  defp publish_item(_repo_path, _item, nil), do: {:ok, %{}}

  defp publish_item(repo_path, item, publication_target) do
    lock_path = Locks.lock_path(repo_path, item.source_path, item.locale)

    payload = %{
      output_path: item.output_path,
      locale: item.locale,
      changes: [
        %{path: item.output_path, status: "modified", content: File.read!(item.output_abs)},
        %{
          path: Path.relative_to(lock_path, repo_path),
          status: "modified",
          content: File.read!(lock_path)
        }
      ]
    }

    target_node = Map.fetch!(publication_target, :node)
    module = Map.fetch!(publication_target, :module)
    context = Map.fetch!(publication_target, :context)

    try do
      if target_node == Node.self() do
        module.publish_item(context, payload)
      else
        :erpc.call(target_node, module, :publish_item, [context, payload], @git_timeout_ms)
      end
    catch
      kind, reason -> {:error, {:publication_relay_failed, kind, reason}}
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

  defp broadcast(session, event, progress_node) do
    TranslationSessions.broadcast_session_event(session, event, progress_node)
  end

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
