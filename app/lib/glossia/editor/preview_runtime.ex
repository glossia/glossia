defmodule Glossia.Editor.PreviewRuntime do
  @moduledoc false
  alias Glossia.{Editor, Repo, Sandboxes}
  alias Glossia.Editor.{Content, Preview, PreviewBrowser, PreviewDiscovery}

  @total_bytes 10_000_000
  @frame_bytes 700_000

  def run(session, user, project, file) do
    adapter = Glossia.Sandbox.adapter()
    project = Repo.preload(project, :account)

    with :ok <- Preview.isolation(),
         {:ok, sandbox} <-
           Sandboxes.create_sandbox(
             project.account,
             project,
             %{
               purpose: "editor_preview",
               deadline_at: DateTime.add(DateTime.utc_now(), 900, :second)
             },
             adapter: adapter
           ) do
      worker = self()
      spawn(fn -> guard_sandbox(session, worker, sandbox, adapter) end)

      with {:ok, root} <- adapter.repo_path(sandbox.id),
           {:ok, repository} <- Editor.repository(project),
           {:ok, files} <- snapshots(user, project, file),
           :ok <- clone(adapter, sandbox.id, root, repository),
           :ok <- check_bases(adapter, sandbox.id, root, files),
           :ok <- shell(adapter, sandbox.id, root, "rm -rf .git"),
           :ok <- write_files(adapter, sandbox.id, root, files),
           :ok <- discover(session, adapter, sandbox.id, root, project, file),
           {:ok, manifest} <- read_manifest(adapter, sandbox.id, root, file),
           {:ok, launch} <- launch_config(manifest, root, file),
           :ok <- install(adapter, sandbox.id, root, manifest),
           :ok <-
             adapter.upload_file(
               sandbox.id,
               sibling(root, "preview-runtime.mjs"),
               PreviewBrowser.source()
             ),
           :ok <-
             adapter.upload_file(
               sandbox.id,
               sibling(root, "preview-launch.json"),
               JSON.encode!(launch)
             ) do
        event(session, %{
          status: :discovering,
          message: "Starting the discovered page and browser."
        })

        parent = self()

        {runtime, monitor} =
          spawn_monitor(fn ->
            result =
              adapter.execute_preview(
                sandbox.id,
                "exec node #{shell_quote(sibling(root, "preview-runtime.mjs"))} #{shell_quote(sibling(root, "preview-launch.json"))}",
                cwd: root,
                timeout_ms: 900_000,
                output_limit_bytes: 4_000,
                env: browser_env(adapter)
              )

            send(parent, {:runtime_done, result})
          end)

        Process.send_after(self(), :poll_preview_frame, 1_000)

        loop(%{
          session: session,
          user: user,
          project: project,
          file: file,
          files: files,
          adapter: adapter,
          id: sandbox.id,
          root: root,
          revision: 0,
          runtime: runtime,
          monitor: monitor,
          path: manifest["path"],
          probe_field: launch["probe_field"],
          inputs: [],
          last_sequence: 0
        })
      else
        {:error, reason} -> fail(session, reason)
      end
    else
      {:error, reason} -> fail(session, reason)
    end
  rescue
    _ -> fail(session, :preview_failed)
  catch
    _, _ -> fail(session, :preview_failed)
  end

  # A separate monitor can delete the sandbox even while clone, discovery or a
  # kubectl exec is blocked. The persisted deadline/reaper remains the fallback
  # if this node itself disappears. Provisioning that finishes after disconnect
  # is also immediately deleted, rather than abandoned.
  defp guard_sandbox(session, worker, sandbox, adapter) do
    session_ref = Process.monitor(session)
    worker_ref = Process.monitor(worker)

    receive do
      {:DOWN, ref, :process, _, _} when ref in [session_ref, worker_ref] ->
        Sandboxes.destroy_sandbox(sandbox, adapter: adapter, reason: "preview_closed")
        if Process.alive?(worker), do: Process.exit(worker, :kill)
    end
  end

  defp snapshots(user, project, file) do
    with {:ok, files} <- Editor.list_files(user, project) do
      current = Enum.find(files, &(&1.id == file.id))

      selected =
        Enum.filter(files, &(&1.active || &1.id == file.id || not is_nil(&1.draft_content)))
        |> Enum.map(fn current ->
          # The owner process alone may adopt a new displayed lock version.
          # A save during provisioning must not inject foreign draft bytes.
          if current.id == file.id,
            do: %{current | draft_content: file.draft_content},
            else: current
        end)

      bytes = Enum.reduce(selected, 0, &(byte_size(&1.draft_content || &1.content) + &2))

      cond do
        is_nil(current) || not Preview.same_base?(current, file) ->
          {:error, :stale}

        bytes > @total_bytes ->
          {:error, :drafts_too_large}

        Enum.any?(selected, &(&1.conflict || not &1.active || not is_nil(&1.branch))) ->
          {:error, :repository_changed}

        Enum.any?(
          selected,
          &(not valid_file_path?(&1.path) || not valid_file_path?(&1.source_path))
        ) ->
          {:error, :invalid_path}

        true ->
          {:ok, selected}
      end
    end
  end

  def valid_file_path?(path) when is_binary(path) do
    Path.type(path) == :relative && path != "" &&
      Enum.all?(Path.split(path), &(&1 not in [".", "..", ".git"])) &&
      not String.contains?(path, [<<0>>, "\\", "\n", "\r"])
  end

  def valid_file_path?(_), do: false

  def valid_route?(path) when is_binary(path) and byte_size(path) <= 2_000 do
    uri = URI.parse(path)
    decoded = URI.decode(path)

    match?(%URI{scheme: nil, host: nil, path: "/" <> _}, uri) &&
      is_nil(uri.fragment) && not String.contains?(decoded, ["\\", <<0>>, "\n", "\r"]) &&
      not Enum.any?(String.to_charlist(decoded), &(&1 < 32)) &&
      is_nil(URI.parse(decoded).host)
  rescue
    _ -> false
  end

  def valid_route?(_), do: false

  defp clone(adapter, id, root, repository) do
    url =
      "https://x-access-token:#{URI.encode_www_form(repository.token)}@github.com/#{repository.full_name}.git"

    # This override is deliberately limited to explicitly trusted local dev.
    url =
      if adapter == Glossia.Sandbox.LocalAdapter && Preview.config(:trusted_local, false),
        do: Preview.config(:local_repository, url),
        else: url

    shell(
      adapter,
      id,
      Path.dirname(root),
      "rmdir #{shell_quote(root)} && git -c credential.helper= -c core.hooksPath=/dev/null clone --no-checkout --single-branch --branch #{shell_quote(repository.default_branch)} #{shell_quote(url)} #{shell_quote(root)} && git -C #{shell_quote(root)} remote remove origin && git -C #{shell_quote(root)} -c core.hooksPath=/dev/null checkout --force HEAD",
      timeout_ms: 180_000,
      env: %{
        "GIT_CONFIG_NOSYSTEM" => "1",
        "GIT_CONFIG_GLOBAL" => "/dev/null",
        "GIT_TERMINAL_PROMPT" => "0"
      }
    )
  end

  defp check_bases(adapter, id, root, files) do
    Enum.reduce_while(files, :ok, fn file, :ok ->
      path = if file.blob_sha, do: file.path, else: file.source_path

      with {:ok, %{"exitCode" => 0, "stdout" => size}} <-
             adapter.execute_preview(id, "git cat-file -s #{shell_quote("HEAD:" <> path)}",
               cwd: root
             ),
           true <- String.trim(size) == to_string(byte_size(file.content)),
           {:ok, %{"exitCode" => 0, "stdout" => content}} <-
             adapter.execute_preview(
               id,
               "git -c core.hooksPath=/dev/null show #{shell_quote("HEAD:" <> path)}",
               cwd: root,
               output_limit_bytes: 1_000_001
             ),
           true <- content == file.content,
           :ok <- check_blob(adapter, id, root, file) do
        {:cont, :ok}
      else
        _ -> {:halt, {:error, :repository_changed}}
      end
    end)
  end

  defp check_blob(adapter, id, root, file) do
    with {:ok, %{"exitCode" => 0, "stdout" => tree}} <-
           adapter.execute_preview(
             id,
             "git ls-tree -z HEAD -- #{shell_quote(file.path)}",
             cwd: root
           ) do
      expected =
        if file.blob_sha,
          do: "#{file.mode} blob #{file.blob_sha}\t#{file.path}" <> <<0>>,
          else: ""

      if tree == expected, do: :ok, else: {:error, :repository_changed}
    end
  end

  defp write_files(adapter, id, root, files) do
    Enum.reduce_while(files, :ok, fn file, :ok ->
      path = Path.join(root, file.path)

      checks =
        path
        |> Path.relative_to(root)
        |> Path.split()
        |> Enum.scan(root, &Path.join(&2, &1))
        |> Enum.map_join(" && ", &("test ! -L " <> shell_quote(&1)))

      with :ok <-
             shell(adapter, id, root, "#{checks} && mkdir -p #{shell_quote(Path.dirname(path))}"),
           :ok <- adapter.upload_file(id, path, file.draft_content || file.content) do
        {:cont, :ok}
      else
        error -> {:halt, error}
      end
    end)
  end

  defp discover(session, adapter, id, root, project, file) do
    event(session, %{
      status: :discovering,
      message: "Inspecting the repository startup and matching route."
    })

    # No provider override in production. The fixture exercises the same
    # runtime with just discovery replaced by a deterministic local provider.
    fixture = Preview.config(:trusted_discovery, nil)

    if adapter == Glossia.Sandbox.LocalAdapter && Preview.config(:trusted_local, false) &&
         is_function(fixture, 4) do
      fixture.(adapter, id, root, file)
    else
      with {:ok, manifest} <- PreviewDiscovery.discover(adapter, id, root, project.account, file) do
        adapter.upload_file(id, sibling(root, "preview-manifest.json"), JSON.encode!(manifest))
      end
    end
  end

  defp install(adapter, id, root, manifest) do
    case manifest["install"] do
      command when is_binary(command) and command != "" ->
        shell(adapter, id, root, "(#{command}) >/dev/null 2>&1", timeout_ms: 180_000)

      _ ->
        :ok
    end
  end

  defp read_manifest(adapter, id, root, file) do
    with {:ok, bytes} <-
           adapter.download_preview_file(id, sibling(root, "preview-manifest.json"), 10_000),
         true <- byte_size(bytes) <= 10_000,
         {:ok, manifest} <- JSON.decode(bytes) do
      validate_manifest(manifest, file)
    else
      _ -> {:error, :discovery_failed}
    end
  end

  def validate_manifest(%{"error" => "ambiguous_route"}, _), do: {:error, :ambiguous_route}

  def validate_manifest(%{"error" => "missing_credentials"}, _),
    do: {:error, :missing_credentials}

  def validate_manifest(%{"error" => "unusable_app"}, _), do: {:error, :unusable_app}

  def validate_manifest(
        %{"command" => command, "path" => path, "evidence" => evidence, "reason" => reason} =
          manifest,
        file
      )
      when is_binary(command) and byte_size(command) in 1..4_000 and is_binary(evidence) and
             byte_size(evidence) in 3..300 and is_binary(reason) and byte_size(reason) in 1..2_000 do
    with true <- valid_route?(path),
         true <-
           is_nil(manifest["install"]) ||
             (is_binary(manifest["install"]) && byte_size(manifest["install"]) <= 4_000),
         {:ok, fields} <- Content.fields(file.format, file.draft_content || file.content),
         true <- Enum.any?(fields, &String.contains?(&1.value, evidence)) do
      {:ok, Map.take(manifest, ["command", "path", "evidence", "reason", "install"])}
    else
      _ -> {:error, :ambiguous_route}
    end
  end

  def validate_manifest(_, _), do: {:error, :discovery_failed}

  defp launch_config(manifest, root, file) do
    content = file.draft_content || file.content
    marker = "GlossiaPreview" <> String.replace(Ecto.UUID.generate(), "-", "")

    with {:ok, fields} <- Content.fields(file.format, content),
         field when not is_nil(field) <-
           Enum.find(fields, &String.contains?(&1.value, manifest["evidence"])),
         {:ok, probe} <-
           Content.update(file.format, content, %{field.id => field.value <> " " <> marker}) do
      {:ok,
       Map.merge(manifest, %{
         "root" => root,
         "probe_path" => file.path,
         "probe_content" => probe,
         "original_content" => content,
         "probe_marker" => marker,
         "probe_field" => field.id
       })}
    else
      _ -> {:error, :ambiguous_route}
    end
  end

  defp loop(state) do
    receive do
      {:update, revision, content, file} ->
        {revision, content, file} = latest(revision, content, file)

        with {:ok, files} <- snapshots(state.user, state.project, file),
             true <-
               Enum.all?(files, fn file ->
                 Enum.any?(state.files, &(&1.id == file.id && Preview.same_base?(&1, file)))
               end),
             :ok <- upload_input(state, files, revision, content) do
          for input <- state.inputs,
              do: send(state.session, {:preview_input_ack, self(), input.sequence})

          loop(%{state | revision: revision, file: file, inputs: []})
        else
          _ -> fail(state.session, :repository_changed)
        end

      {:interact, revision, sequence, input} when revision == state.revision ->
        inputs = state.inputs ++ [%{sequence: sequence, input: input}]

        if length(inputs) <= 32 &&
             state.adapter.upload_file(
               state.id,
               sibling(state.root, "preview-interactions.json"),
               JSON.encode!(%{revision: revision, inputs: inputs})
             ) == :ok do
          loop(%{state | inputs: inputs})
        else
          fail(state.session, :preview_failed)
        end

      {:interact, _, sequence, _} ->
        send(state.session, {:preview_input_ack, self(), sequence})
        loop(state)

      {:runtime_done, _result} ->
        fail(state.session, :unusable_app)

      {:DOWN, ref, :process, _, _} when ref == state.monitor ->
        fail(state.session, :unusable_app)

      :poll_preview_frame ->
        Process.send_after(self(), :poll_preview_frame, 1_000)

        case read_frame(state) do
          {:ok, frame, revision, sequence, input_sequence}
          when revision == state.revision and sequence > state.last_sequence ->
            send(state.session, {:preview_input_ack, self(), input_sequence})

            event(state.session, %{
              status: :ready,
              message: "Live app preview",
              frame: frame,
              path: state.path,
              revision: revision
            })

            loop(%{
              state
              | last_sequence: sequence,
                inputs: Enum.reject(state.inputs, &(&1.sequence <= input_sequence))
            })

          _ ->
            loop(state)
        end
    end
  end

  defp latest(revision, content, file) do
    receive do
      {:update, next, value, snapshot} -> latest(next, value, snapshot)
    after
      0 -> {revision, content, file}
    end
  end

  defp upload_input(state, files, revision, content) do
    files =
      Enum.map(files, fn f ->
        %{
          path: f.path,
          content: if(f.id == state.file.id, do: content, else: f.draft_content || f.content)
        }
      end)

    if Enum.reduce(files, 0, &(byte_size(&1.content) + &2)) <= @total_bytes do
      marker = "GlossiaPreview" <> String.replace(Ecto.UUID.generate(), "-", "")

      with {:ok, fields} <- Content.fields(state.file.format, content),
           field when not is_nil(field) <- Enum.find(fields, &(&1.id == state.probe_field)),
           {:ok, probe} <-
             Content.update(state.file.format, content, %{
               field.id => field.value <> " " <> marker
             }) do
        payload =
          JSON.encode!(%{
            revision: revision,
            files: files,
            probe_content: probe,
            probe_marker: marker
          })

        if byte_size(payload) <= 12_000_000 do
          state.adapter.upload_file(state.id, sibling(state.root, "preview-input.json"), payload)
        else
          {:error, :drafts_too_large}
        end
      else
        _ -> {:error, :ambiguous_route}
      end
    else
      {:error, :drafts_too_large}
    end
  end

  defp read_frame(state) do
    with {:ok, bytes} <-
           state.adapter.download_preview_file(
             state.id,
             sibling(state.root, "preview-frame.json"),
             @frame_bytes
           ),
         true <- byte_size(bytes) <= @frame_bytes,
         {:ok,
          %{
            "frame" => frame,
            "revision" => revision,
            "sequence" => sequence,
            "input_sequence" => input_sequence
          }} <-
           JSON.decode(bytes),
         true <- is_integer(sequence) && sequence > 0 && is_integer(revision),
         true <- is_integer(input_sequence) && input_sequence >= 0,
         true <- is_binary(frame) && byte_size(frame) <= @frame_bytes,
         {:ok, <<255, 216, _::binary>>} <- Base.decode64(frame) do
      {:ok, frame, revision, sequence, input_sequence}
    else
      _ -> {:error, :frame_unavailable}
    end
  end

  defp shell(adapter, id, root, command, opts \\ []) do
    case adapter.execute_preview(id, command, Keyword.put(opts, :cwd, root)) do
      {:ok, %{"exitCode" => 0}} -> :ok
      _ -> {:error, :preview_failed}
    end
  end

  defp fail(session, reason),
    do: event(session, %{status: :error, message: failure_message(reason)})

  defp failure_message(:repository_changed),
    do: "The repository no longer matches this editor snapshot. Synchronize before previewing."

  defp failure_message(:ambiguous_route), do: "Could not identify one page displaying this file."

  defp failure_message(:missing_credentials),
    do: "This app needs credentials that are not available in the isolated preview."

  defp failure_message(:preview_model_auth_unavailable),
    do:
      "Preview discovery needs a supported account model API key or direct OAuth session. CLI-only credentials are not supported."

  defp failure_message(:sandbox_quota_exceeded),
    do: "The account's sandbox limit has been reached. Stop another sandbox and retry."

  defp failure_message(_),
    do:
      "The repository app could not be previewed safely. Check its development startup and route configuration."

  defp event(session, event), do: send(session, {:preview_event, self(), event})
  defp sibling(root, name), do: Path.join(Path.dirname(root), name)
  defp shell_quote(value), do: "'" <> String.replace(value, "'", "'\"'\"'") <> "'"

  defp browser_env(Glossia.Sandbox.LocalAdapter) do
    env =
      case Preview.config(:chromium, nil) do
        path when is_binary(path) -> %{"GLOSSIA_PREVIEW_CHROMIUM" => path}
        _ -> %{}
      end

    env
    |> Map.put("GLOSSIA_PREVIEW_PORT", to_string(Preview.config(:local_port, 4173)))
    |> Map.put(
      "GLOSSIA_PREVIEW_BROWSER_PORT",
      to_string(Preview.config(:local_browser_port, 9222))
    )
  end

  defp browser_env(_), do: %{}
end
