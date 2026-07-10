defmodule Glossia.Projects.SetupHarness do
  @moduledoc false

  alias Glossia.Sandbox.HarnessEventPoller

  @change_manifest_filename "glossia-setup-changes.json"
  @context_filename "glossia-harness-context.md"
  @output_filename "glossia-setup-harness-output.jsonl"
  @prompt_version "setup-harness-v2"
  @internal_path_prefixes [".git/", ".opencode/", ".glossia/", "node_modules/"]
  @internal_paths MapSet.new(["opencode.json", @change_manifest_filename, @output_filename])

  def run(callbacks, caller, opts) when is_pid(caller) do
    result = do_run(callbacks, caller, opts)

    case result do
      :ok ->
        emit(caller, "completed", "Setup harness completed.")
        :ok

      {:error, reason} ->
        emit(caller, "failed", failure_message(reason))
        {:error, reason}
    end
  end

  def output_filename, do: @output_filename
  def change_manifest_filename, do: @change_manifest_filename

  def build_prompt(target_languages) do
    target_languages = if is_list(target_languages), do: target_languages, else: []

    targets =
      if target_languages == [],
        do: "infer from repository conventions",
        else: Enum.join(target_languages, ", ")

    target_instruction =
      if target_languages == [] do
        "Infer target languages conservatively and keep the list minimal."
      else
        "Use exactly these target languages: #{targets}."
      end

    [
      "Set up Glossia localization for this repository.",
      "",
      "Primary objective",
      "- Make the smallest complete repository change that lets the project serve localized content.",
      "- Extract user-facing source content into localized files or an existing localization structure.",
      "- Configure the project to load those localized files for the requested target languages.",
      "- Configure Glossia context and workflow files so future translation runs understand the project.",
      "",
      "Glossia configuration files",
      "- This product currently uses GLOSSIA.md as the canonical Glossia configuration and context file.",
      "- If the repository already has GLOSSIA.md or scoped GLOSSIA.md files, update them.",
      "- If neither exists, create a root GLOSSIA.md.",
      "- Use YAML frontmatter between --- markers.",
      "- Valid root frontmatter has this shape:",
      "  ---",
      "  source_language: en",
      "  sources:",
      "    \"docs/**/*.md\": \"docs/i18n/{locale}/{relpath}\"",
      "  targets:",
      "    - es",
      "  ---",
      "- Root GLOSSIA.md must declare source_language when the repository does not already do so.",
      "- Declare sources as a mapping of source globs to translated output templates.",
      "- Declare targets as the selected locale codes.",
      "- Scoped files use the same GLOSSIA.md filename inside subdirectories.",
      "- Locale-specific context belongs in GLOSSIA/<locale>.md.",
      "- Use validation only when the repository already has a clear lightweight command for translated outputs.",
      "- Add brief free-text context below frontmatter that captures product context, audience, and tone.",
      "- Do not create translation lockfiles during setup. Glossia owns translation runs and writes `.glossia/` state later.",
      "",
      "Localization requirements",
      "- #{target_instruction}",
      "- Ensure the selected language preferences are reflected in targets.",
      "- Use output templates with {locale}, {relpath}, {basename}, and {ext} for translated paths when GLOSSIA.md is used.",
      "- Keep source language behavior unchanged.",
      "- Prefer the repository's existing localization library, framework conventions, and file layout.",
      "- If the project has no localization setup, add a minimal one that matches its stack.",
      "",
      "Definition of done",
      "- The repository has concrete changed files, not just an explanation.",
      "- At least one Glossia context file is created or updated.",
      "- User-facing content has been extracted for localization where practical.",
      "- Project configuration or application code loads the selected localized files.",
      "- Run a lightweight verification command if the repository makes one obvious.",
      "- Do not modify files outside the cloned repository.",
      "- Keep the result minimal enough for reviewers to merge as a baseline."
    ]
    |> Enum.join("\n")
  end

  def open_code_event(line) when is_binary(line) do
    trimmed = String.trim(line)

    if trimmed == "" do
      nil
    else
      case JSON.decode(trimmed) do
        {:ok, %{"event_type" => event_type} = event} when is_binary(event_type) ->
          event

        {:ok, event} when is_map(event) ->
          map_open_code_event(event, trimmed)

        _ ->
          %{
            "event_type" => "harness_output",
            "content" => String.slice(trimmed, 0, 700),
            "metadata" => %{}
          }
      end
    end
  end

  defp do_run(callbacks, caller, opts) do
    repo_path = Keyword.fetch!(opts, :repo_path)
    repository = Keyword.fetch!(opts, :repository)
    harness = Keyword.get(opts, :harness, %{})
    target_languages = Keyword.get(opts, :target_languages, [])
    timeout_ms = Keyword.get(opts, :timeout_ms, 660_000)
    parent_path = Path.dirname(repo_path)
    output_path = Path.join(parent_path, @output_filename)
    manifest_path = Path.join(parent_path, @change_manifest_filename)

    with :ok <- put_file(callbacks, output_path, ""),
         :ok <- clone_repository(callbacks, caller, repository, repo_path),
         {:ok, env} <- configure_open_code(callbacks, repo_path, harness),
         {:ok, context_path} <- write_context(callbacks, repo_path, harness),
         {:ok, poller} <- start_poller(callbacks, caller, output_path),
         :ok <-
           run_open_code(
             callbacks,
             caller,
             repo_path,
             output_path,
             target_languages,
             harness,
             context_path,
             env,
             timeout_ms,
             poller
           ),
         {:ok, files} <- collect_changed_files(callbacks, repo_path),
         :ok <- write_manifest(callbacks, manifest_path, files) do
      emit(caller, "status", "Detected #{length(files)} changed repository file(s).")
      :ok
    end
  end

  defp clone_repository(callbacks, caller, repository, repo_path) do
    emit(caller, "status", "Preparing repository...")

    full_name = get_value(repository, :full_name)
    default_branch = get_value(repository, :default_branch) || "main"
    token = get_value(repository, :token)
    clone_url = clone_url(full_name, token)

    command =
      [
        "rm -rf #{shell_quote(repo_path)}",
        "mkdir -p #{shell_quote(Path.dirname(repo_path))}",
        "git clone --branch #{shell_quote(default_branch)} #{shell_quote(clone_url)} #{shell_quote(repo_path)}"
      ]
      |> Enum.join(" && ")

    case exec(callbacks, command, timeout_ms: 180_000, output_limit_bytes: 200_000) do
      {:ok, %{"exitCode" => 0}} -> :ok
      {:ok, result} -> {:error, {:clone_failed, command_result_summary(result)}}
      {:error, reason} -> {:error, {:clone_failed, reason}}
    end
  end

  defp clone_url(full_name, nil), do: "https://github.com/#{full_name}.git"
  defp clone_url(full_name, ""), do: "https://github.com/#{full_name}.git"

  defp clone_url(full_name, token) do
    "https://x-access-token:#{URI.encode_www_form(to_string(token))}@github.com/#{full_name}.git"
  end

  defp configure_open_code(callbacks, repo_path, harness) do
    harness_env = normalize_env(get_value(harness, :env) || %{})
    model = get_value(harness, :model)
    opencode_config = normalize_map(get_value(harness, :opencode_config) || %{})

    opencode_config =
      if is_binary(model) and model != "" and not Map.has_key?(opencode_config, "model") do
        Map.put(opencode_config, "model", model)
      else
        opencode_config
      end

    if map_size(opencode_config) == 0 do
      {:ok, harness_env}
    else
      harness_home = Path.join(Path.dirname(repo_path), ".glossia-harness")
      config_home = Path.join(harness_home, ".config")
      cache_home = Path.join(harness_home, ".cache")
      config_path = Path.join([config_home, "opencode", "opencode.json"])

      opencode_config = Map.put_new(opencode_config, "$schema", "https://opencode.ai/config.json")

      with :ok <- mkdir(callbacks, [Path.dirname(config_path), cache_home]),
           :ok <- put_file(callbacks, config_path, JSON.encode!(opencode_config)) do
        {:ok,
         Map.merge(harness_env, %{
           "XDG_CONFIG_HOME" => config_home,
           "XDG_CACHE_HOME" => cache_home
         })}
      end
    end
  end

  defp write_context(callbacks, repo_path, harness) do
    context = get_value(harness, :context)

    if is_binary(context) and String.trim(context) != "" do
      context_path = Path.join(Path.dirname(repo_path), @context_filename)

      case put_file(callbacks, context_path, context) do
        :ok -> {:ok, context_path}
        {:error, _reason} = error -> error
      end
    else
      {:ok, nil}
    end
  end

  defp start_poller(callbacks, caller, output_path) do
    download = fetch_callback!(callbacks, :download_file)

    HarnessEventPoller.start(fn path -> download.(path) end, caller, output_path,
      mapper: &__MODULE__.open_code_event/1
    )
  end

  defp run_open_code(
         callbacks,
         caller,
         repo_path,
         output_path,
         target_languages,
         harness,
         context_path,
         env,
         timeout_ms,
         poller
       ) do
    prompt = build_prompt(target_languages)
    command = harness_command(repo_path, prompt, harness, context_path)

    emit(caller, "prompt", prompt, %{"prompt_version" => @prompt_version})

    emit(
      caller,
      "status",
      "Starting #{get_value(harness, :command) || "opencode"} in headless mode..."
    )

    result =
      exec(callbacks, "#{command} >> #{shell_quote(output_path)} 2>&1",
        cwd: repo_path,
        env: env,
        timeout_ms: timeout_ms,
        output_limit_bytes: 128_000
      )

    HarnessEventPoller.stop(poller)

    case result do
      {:ok, %{"exitCode" => 0}} -> :ok
      {:ok, result} -> {:error, {:harness_failed, command_result_summary(result)}}
      {:error, reason} -> {:error, {:harness_failed, reason}}
    end
  end

  defp harness_command(repo_path, prompt, harness, context_path) do
    command = get_value(harness, :command) || "opencode"

    args =
      [command]
      |> maybe_append_open_code_pure(harness)
      |> Kernel.++(["run", "--dir", repo_path, "--format", "json", "--auto"])
      |> maybe_append("--model", get_value(harness, :model))
      |> maybe_append("--agent", get_value(harness, :agent))
      |> append_prompt(prompt)
      |> maybe_append_file(context_path)

    args
    |> Enum.map(&shell_quote/1)
    |> Enum.join(" ")
  end

  defp collect_changed_files(callbacks, repo_path) do
    result =
      exec(callbacks, "git status --porcelain=v1 --untracked-files=all",
        cwd: repo_path,
        output_limit_bytes: 1_000_000
      )

    case result do
      {:ok, %{"exitCode" => 0, "stdout" => stdout}} ->
        files =
          stdout
          |> Glossia.Git.PorcelainStatus.parse()
          |> Enum.reject(&internal_path?(&1.path))
          |> Map.new(fn %{path: path, status: status} -> {path, status} end)
          |> Enum.map(fn {path, status} -> %{path: path, status: status} end)
          |> Enum.sort_by(& &1.path)

        {:ok, files}

      {:ok, result} ->
        {:error, {:status_failed, command_result_summary(result)}}

      {:error, reason} ->
        {:error, {:status_failed, reason}}
    end
  end

  defp internal_path?(path) do
    MapSet.member?(@internal_paths, path) or
      Enum.any?(@internal_path_prefixes, &String.starts_with?(path, &1))
  end

  defp write_manifest(callbacks, manifest_path, files) do
    put_file(callbacks, manifest_path, JSON.encode!(%{version: 1, files: files}))
  end

  defp map_open_code_event(%{"type" => "text", "part" => %{"text" => text}}, _raw)
       when is_binary(text) do
    if String.trim(text) == "" do
      nil
    else
      %{"event_type" => "text", "content" => text, "metadata" => %{"source" => "opencode"}}
    end
  end

  defp map_open_code_event(%{"type" => "tool_use", "part" => part}, _raw) when is_map(part) do
    state = Map.get(part, "state", %{}) || %{}
    tool_name = Map.get(part, "tool") || Map.get(state, "title") || "tool"

    events = [
      %{
        "event_type" => "tool_call",
        "content" => Map.get(state, "title") || tool_name,
        "metadata" => %{
          "source" => "opencode",
          "tool_name" => tool_name,
          "status" => Map.get(state, "status", "")
        }
      }
    ]

    if Map.get(state, "status") == "completed" and Map.get(state, "output") do
      events ++
        [
          %{
            "event_type" => "tool_result",
            "content" => state |> Map.get("output") |> to_string() |> String.slice(0, 1200),
            "metadata" => %{
              "source" => "opencode",
              "tool_name" => tool_name,
              "status" => Map.get(state, "status")
            }
          }
        ]
    else
      events
    end
  end

  defp map_open_code_event(%{"type" => type}, _raw) when type in ["step_start", "step_finish"],
    do: nil

  defp map_open_code_event(_event, raw) do
    %{
      "event_type" => "harness_output",
      "content" => String.slice(raw, 0, 700),
      "metadata" => %{"source" => "opencode"}
    }
  end

  defp maybe_append(args, _flag, nil), do: args
  defp maybe_append(args, _flag, ""), do: args
  defp maybe_append(args, flag, value), do: args ++ [flag, value]

  defp maybe_append_open_code_pure(args, harness) do
    if open_code_harness?(harness) and get_value(harness, :pure) != false do
      args ++ ["--pure"]
    else
      args
    end
  end

  defp open_code_harness?(harness) do
    name = harness |> get_value(:name) || "opencode"
    command = harness |> get_value(:command) || "opencode"

    name = name |> to_string() |> String.downcase()
    command = command |> to_string() |> String.downcase()

    name in ["", "opencode"] or String.ends_with?(command, "/opencode") or command == "opencode"
  end

  defp append_prompt(args, prompt), do: args ++ [prompt]

  defp maybe_append_file(args, nil), do: args
  defp maybe_append_file(args, path), do: args ++ ["--file=#{path}"]

  defp mkdir(callbacks, paths) do
    command = "mkdir -p " <> (paths |> Enum.map(&shell_quote/1) |> Enum.join(" "))

    case exec(callbacks, command) do
      {:ok, %{"exitCode" => 0}} -> :ok
      {:ok, result} -> {:error, {:mkdir_failed, command_result_summary(result)}}
      {:error, reason} -> {:error, {:mkdir_failed, reason}}
    end
  end

  defp exec(callbacks, command, opts \\ []) do
    execute_shell = fetch_callback!(callbacks, :execute_shell)
    execute_shell.(command, opts)
  end

  defp put_file(callbacks, path, content) do
    upload_file = fetch_callback!(callbacks, :upload_file)
    upload_file.(path, content)
  end

  defp fetch_callback!(callbacks, key) when is_map(callbacks), do: Map.fetch!(callbacks, key)
  defp fetch_callback!(callbacks, key) when is_list(callbacks), do: Keyword.fetch!(callbacks, key)

  defp emit(caller, event_type, content, metadata \\ %{}) do
    send(
      caller,
      {:agent_event, %{"event_type" => event_type, "content" => content, "metadata" => metadata}}
    )
  end

  defp get_value(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, to_string(key))
  end

  defp get_value(_map, _key), do: nil

  defp normalize_env(env) when is_map(env) do
    Map.new(env, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_env(env) when is_list(env) do
    Map.new(env, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp normalize_env(_env), do: %{}

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_map(_map), do: %{}

  defp command_result_summary(%{"stdout" => stdout, "stderr" => stderr, "exitCode" => exit_code}) do
    [stderr, stdout]
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
    |> case do
      "" -> "exit #{exit_code}"
      output -> "exit #{exit_code}: #{String.slice(output, 0, 2_000)}"
    end
  end

  defp command_result_summary(result), do: inspect(result)

  defp failure_message({:clone_failed, _reason}), do: "Failed to clone repository."
  defp failure_message({:harness_failed, _reason}), do: "The setup harness command failed."
  defp failure_message({:status_failed, _reason}), do: "Could not inspect setup changes."
  defp failure_message(reason), do: "Setup harness failed: #{inspect(reason)}"

  defp shell_quote(value) do
    "'" <> (value |> to_string() |> String.replace("'", "'\"'\"'")) <> "'"
  end
end
