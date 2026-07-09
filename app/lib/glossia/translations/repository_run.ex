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

  alias Glossia.Translations.Engine
  alias Glossia.Translations.Locks
  alias Glossia.Translations.Planner
  alias Glossia.Translations.Validate
  alias Glossia.TranslationSessions

  @clone_timeout_ms 600_000

  @doc """
  Clones `repository`, translates `locales`, and returns `{:ok, changes}`.

  `changes` is a list of `%{path, status, content}` where `status` is
  `"added" | "modified" | "deleted"`, ready for the PR builder.
  """
  def run(session, account, repository, locales) do
    FLAME.call(
      Glossia.Flame.pool_name(),
      fn ->
        case clone(repository) do
          {:ok, repo_path} ->
            try do
              translate_repository(session, account, repo_path, locales)
            after
              File.rm_rf(repo_path)
            end

          {:error, _reason} = error ->
            error
        end
      end,
      timeout: @clone_timeout_ms
    )
  end

  @doc "Plans, translates, and collects changes for a checked-out repo at `repo_path`."
  def translate_repository(session, account, repo_path, locales) do
    items = build_items(repo_path, locales)
    total = length(items)
    broadcast(session, %{type: "plan", total: total})

    items
    |> Enum.with_index()
    |> Enum.each(fn {item, index} -> apply_one(session, account, repo_path, item, index, total) end)

    collect_changes(repo_path)
  end

  # Plan the whole repository once (walking the filesystem and parsing the
  # GLOSSIA.md chains a single time) and filter to the requested locales in
  # memory, rather than re-planning per locale on the hot runner path.
  defp build_items(repo_path, locales) do
    case Planner.build_plan(repo_path) do
      {:ok, items} -> filter_locales(items, locales)
      {:error, _reason} -> []
    end
  end

  defp filter_locales(items, []), do: items
  defp filter_locales(items, locales), do: Enum.filter(items, &(&1.locale in locales))

  defp apply_one(session, account, repo_path, item, index, total) do
    source_content = File.read!(item.source_abs)
    provider = provider_of(item.model)

    hash =
      Locks.build_hash(
        item.format,
        source_content,
        provider,
        item.model || "",
        item.context_body,
        item.locale_override_body
      )

    current_output_hash =
      if File.exists?(item.output_abs),
        do: Locks.output_hash(File.read!(item.output_abs)),
        else: ""

    lock = Locks.read_lock(repo_path, item.source_path, item.locale)

    if Locks.stale?(lock, hash, item.output_path, current_output_hash) do
      translate_item(session, account, repo_path, item, index, total, provider, hash)
    else
      broadcast(session, %{type: "item_skipped", index: index, output_path: item.output_path})
    end
  end

  defp translate_item(session, account, repo_path, item, index, total, provider, hash) do
    broadcast(session, %{
      type: "item_started",
      index: index,
      total: total,
      output_path: item.output_path,
      locale: item.locale
    })

    on_event = fn event ->
      broadcast(session, %{
        type: "item_event",
        index: index,
        output_path: item.output_path,
        event: normalize_event(event)
      })
    end

    validate = fn output, source ->
      Validate.validate_output(repo_path, item.format, output, source, validate_opts(repo_path, item))
    end

    case Engine.apply_item(item, account, on_event, validate) do
      {:ok, result} ->
        write_output(item, result.text)
        write_lock(repo_path, item, provider, hash, result.text)
        broadcast(session, %{type: "item_completed", index: index, output_path: item.output_path})

      {:error, reason} ->
        broadcast(session, %{
          type: "item_failed",
          index: index,
          output_path: item.output_path,
          reason: inspect(reason)
        })
    end
  end

  defp write_output(item, text) do
    File.mkdir_p!(Path.dirname(item.output_abs))
    File.write!(item.output_abs, text)
  end

  defp write_lock(repo_path, item, provider, hash, text) do
    lock = Locks.build_lock(provider, item.model || "", item.source_path, item.output_path, text, hash)
    Locks.write_lock(repo_path, item.source_path, item.locale, lock)
  end

  defp validate_opts(repo_path, item) do
    %{
      preserve: item.preserve,
      check_cmd: item.check_cmd,
      check_cmds: item.check_cmds,
      validation: item.validation,
      validation_cwd: validation_cwd(repo_path, item.validation_relative_path),
      validation_doc_abs: item.validation_relative_path && Path.join(repo_path, item.validation_relative_path),
      source_abs: item.source_abs,
      target_abs: item.output_abs,
      locale: item.locale
    }
  end

  defp validation_cwd(_repo_path, nil), do: nil
  defp validation_cwd(repo_path, relative_path), do: Path.dirname(Path.join(repo_path, relative_path))

  # ── change collection (git status) ────────────────────────────────────────

  @doc "Collects changed files under `repo_path` as `%{path, status, content}`."
  def collect_changes(repo_path) do
    # `--untracked-files=all` lists new files individually instead of collapsing
    # untracked directories (e.g. `docs/i18n/`, `.glossia/`) into a single entry.
    case System.cmd(
           "git",
           ["-C", repo_path, "status", "--porcelain", "--untracked-files=all"],
           stderr_to_stdout: true
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

    case System.cmd("git", ["clone", "--branch", branch, source, dir], stderr_to_stdout: true) do
      {_output, 0} ->
        checkout_commit(dir, repository[:commit_sha])
        {:ok, dir}

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
    System.cmd("git", ["-C", dir, "checkout", sha], stderr_to_stdout: true)
    :ok
  end

  # ── helpers ─────────────────────────────────────────────────────────────

  defp provider_of(nil), do: ""

  defp provider_of(model) do
    case String.split(model, ":", parts: 2) do
      [provider, _model] -> provider
      _ -> ""
    end
  end

  defp broadcast(session, event), do: TranslationSessions.broadcast_session_event(session, event)

  defp normalize_event(:agent_start), do: %{type: "agent_start"}
  defp normalize_event(:agent_end), do: %{type: "agent_end"}
  defp normalize_event(:turn_start), do: %{type: "turn_start"}
  defp normalize_event(:turn_end), do: %{type: "turn_end"}
  defp normalize_event(:done), do: %{type: "done"}
  defp normalize_event({:text, chunk}), do: %{type: "text", text: chunk}
  defp normalize_event({:thinking, chunk}), do: %{type: "thinking", text: chunk}

  defp normalize_event({:tool_call, name, id, args}),
    do: %{type: "tool_call", name: to_string(name), id: to_string(id), args: inspect(args)}

  defp normalize_event({:tool_result, id, result}),
    do: %{type: "tool_result", id: to_string(id), result: inspect(result)}

  defp normalize_event({:error, reason}), do: %{type: "error", reason: inspect(reason)}
  defp normalize_event(other), do: %{type: "unknown", raw: inspect(other)}
end
