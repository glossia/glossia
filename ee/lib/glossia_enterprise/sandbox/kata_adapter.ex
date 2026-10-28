defmodule GlossiaEnterprise.Sandbox.KataAdapter do
  @moduledoc """
  Kubernetes-backed sandbox adapter.

  Each sandbox is a short-lived Kubernetes Pod. Pod create/delete goes
  through the existing `GlossiaEnterprise.Kubernetes` API client (same one the
  translation-Job launcher uses). Everything that interacts with the running
  pod — command execution, file transfer — shells out to `kubectl` so we
  don't have to reimplement SPDY/WebSocket exec streaming from Elixir.

  ## Placement and isolation

  The pod is placed exactly like the runner pods and translation Jobs: node
  selector, tolerations, affinity, and runtime class all come from the managed
  runner settings (`GLOSSIA_MANAGED_*`). On a cluster whose nodes offer a
  microVM runtime, setting `GLOSSIA_MANAGED_RUNTIME_CLASS_NAME` (for example
  `kata-qemu`) gives every one of those workloads a dedicated kernel. On a
  cluster without one the runtime class stays unset and the pod runs on the
  default runtime; naming a RuntimeClass that does not exist makes the API
  server reject the pod, which fails every project setup.

  Independently of the runtime, the container never gets a service-account
  token, cannot escalate privileges, and drops every Linux capability.

  The old `MicrosandboxAdapter` shipped as a local `msb` invocation that
  required a specific binary on the host. This adapter uses the same Kata
  primitive already installed on production nodes for FLAME runner pods.

  ## Requirements

  * `kubectl` in the release image, with a kubeconfig that lets it talk to
    the in-cluster API. The parent pod's service-account token is used
    automatically.
  * The Pod is created in the same namespace as the caller.
  * The pod's `serviceAccountName` is set to `nil` — the sandbox does not
    need the parent's service account.
  """

  @behaviour Glossia.Sandbox

  require Logger

  alias Glossia.Sandbox.Output
  alias GlossiaEnterprise.Kubernetes

  @default_image "ghcr.io/glossia/glossia:main-enterprise"
  @default_repo_path "/tmp/glossia/repo"
  @kubectl_timeout_ms 30_000
  @exec_timeout_ms 300_000
  @create_wait_timeout_ms 120_000

  @impl true
  def create(params) when is_map(params) do
    sandbox_id = to_string(params[:id] || params["id"] || Ecto.UUID.generate())
    name = sandbox_name(sandbox_id)

    with {:ok, namespace} <- Kubernetes.namespace(),
         {:ok, manifest} <- build_manifest(name, params),
         {:ok, _pod} <- Kubernetes.create_pod(namespace, manifest),
         :ok <- wait_ready(namespace, name) do
      {:ok, sandbox_id}
    else
      {:error, :already_exists} ->
        # A retried create finds the pod it already scheduled: succeed.
        {:ok, sandbox_id}

      {:error, reason} ->
        {:error, {:kata_create_failed, reason}}
    end
  end

  @impl true
  def execute(sandbox_id, command, opts \\ []) do
    with {:ok, argv} <- split_command(command),
         cwd <- Keyword.get(opts, :cwd, configured(:repo_path, @default_repo_path)),
         env <- Keyword.get(opts, :env, %{}),
         {:ok, namespace} <- Kubernetes.namespace() do
      args =
        [
          "exec",
          "-n",
          namespace,
          sandbox_name(sandbox_id),
          "--"
        ] ++ shell_wrap(cwd, env, argv)

      case kubectl(args, timeout: @exec_timeout_ms) do
        {output, exit_code} ->
          {:ok,
           %{
             "exitCode" => exit_code,
             "stdout" => output,
             "stderr" => "",
             "timedOut" => false
           }
           |> Output.truncate(configured(:output_limit_bytes, 256_000))}
      end
    end
  end

  @impl true
  def delete(sandbox_id) do
    with {:ok, namespace} <- Kubernetes.namespace() do
      case Kubernetes.delete_pod(namespace, sandbox_name(sandbox_id)) do
        {:ok, _body} -> :ok
        {:error, :not_found} -> :ok
        {:error, reason} -> {:error, {:kata_delete_failed, reason}}
      end
    end
  end

  @impl true
  def upload_file(sandbox_id, path, content) when is_binary(content) do
    with :ok <- ensure_safe_path(path),
         {:ok, namespace} <- Kubernetes.namespace() do
      tmp = Path.join(System.tmp_dir!(), "glossia-upload-#{System.unique_integer([:positive])}")

      try do
        File.write!(tmp, content)

        args = [
          "cp",
          "-n",
          namespace,
          tmp,
          "#{sandbox_name(sandbox_id)}:#{sandbox_path(path)}"
        ]

        case kubectl(args, timeout: @kubectl_timeout_ms) do
          {_out, 0} -> :ok
          {out, code} -> {:error, {:kata_upload_failed, code, out}}
        end
      after
        File.rm(tmp)
      end
    end
  end

  @impl true
  def download_file(sandbox_id, path) do
    with :ok <- ensure_safe_path(path),
         {:ok, namespace} <- Kubernetes.namespace() do
      tmp = Path.join(System.tmp_dir!(), "glossia-download-#{System.unique_integer([:positive])}")

      try do
        args = [
          "cp",
          "-n",
          namespace,
          "#{sandbox_name(sandbox_id)}:#{sandbox_path(path)}",
          tmp
        ]

        case kubectl(args, timeout: @kubectl_timeout_ms) do
          {_out, 0} -> {:ok, File.read!(tmp)}
          {out, _code} -> {:error, {:kata_download_failed, out}}
        end
      after
        File.rm(tmp)
      end
    end
  end

  @impl true
  def delete_file(sandbox_id, path) do
    with :ok <- ensure_safe_path(path) do
      case execute(sandbox_id, "rm -f #{sandbox_path(path)}") do
        {:ok, %{"exitCode" => 0}} -> :ok
        {:ok, %{"exitCode" => code}} -> {:error, {:kata_delete_file_failed, code}}
        error -> error
      end
    end
  end

  @impl true
  def repo_path(_sandbox_id), do: {:ok, configured(:repo_path, @default_repo_path)}

  @impl true
  def start_agent_session(sandbox_id, caller, opts) do
    # Runs the harness agent inside the pod and forwards its NDJSON event
    # stream back to `caller` as `{:agent_event, event}` / `{:agent_done, _}`.
    task_supervisor = Application.get_env(:glossia, :agent_task_supervisor)

    fun = fn -> run_agent_session(sandbox_id, caller, opts) end

    case task_supervisor do
      nil ->
        {:ok, spawn_link(fun)}

      supervisor ->
        Task.Supervisor.start_child(supervisor, fun)
    end
  end

  # ── manifest ────────────────────────────────────────────────────────────

  @doc false
  def build_manifest(name, params) do
    image = params[:image] || params["image"] || configured(:image, @default_image)
    repo_path = configured(:repo_path, @default_repo_path)
    deadline = params[:deadline_at] || params["deadline_at"]

    {:ok,
     %{
       "apiVersion" => "v1",
       "kind" => "Pod",
       "metadata" => %{
         "name" => name,
         "labels" => %{
           "app.kubernetes.io/name" => "glossia",
           "app.kubernetes.io/component" => "sandbox",
           "glossia.ai/sandbox-id" => name
         }
       },
       "spec" =>
         %{
           "restartPolicy" => "Never",
           "automountServiceAccountToken" => false,
           "containers" => [
             %{
               "name" => "sandbox",
               "image" => image,
               "command" => ["/bin/sh", "-c", "mkdir -p #{repo_path}; exec sleep infinity"],
               # Not the repository path: the container runtime creates a missing
               # working directory as root, and the image runs as an unprivileged
               # user that must own the repository path and its parent in order to
               # clone into it and keep the harness home next to it. Every command
               # sets its own directory, so this only has to exist and be writable.
               "workingDir" => "/tmp",
               "securityContext" => %{
                 "allowPrivilegeEscalation" => false,
                 "capabilities" => %{"drop" => ["ALL"]}
               },
               "resources" => %{
                 "requests" => %{"cpu" => "500m", "memory" => "1Gi"},
                 "limits" => %{"cpu" => "2", "memory" => "4Gi"}
               }
             }
           ]
         }
         |> maybe_put("nodeSelector", placement(:node_selector))
         |> maybe_put("tolerations", placement(:tolerations))
         |> maybe_put("affinity", placement(:affinity))
         |> maybe_put("runtimeClassName", placement(:runtime_class_name))
         |> maybe_put("activeDeadlineSeconds", active_deadline_seconds(deadline))
     }}
  end

  defp active_deadline_seconds(nil), do: nil

  defp active_deadline_seconds(%DateTime{} = deadline) do
    max(DateTime.diff(deadline, DateTime.utc_now(), :second), 1)
  end

  defp active_deadline_seconds(_), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, _key, value) when value == %{}, do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp placement(key) do
    :glossia
    |> Application.get_env(:managed_runner, [])
    |> Keyword.get(:k8s, [])
    |> Keyword.get(key)
  end

  # ── waiting ────────────────────────────────────────────────────────────

  defp wait_ready(namespace, name) do
    deadline = System.monotonic_time(:millisecond) + @create_wait_timeout_ms
    poll_ready(namespace, name, deadline)
  end

  defp poll_ready(namespace, name, deadline) do
    case Kubernetes.get_pod(namespace, name) do
      {:ok, %{"status" => %{"phase" => "Running"}}} ->
        :ok

      {:ok, %{"status" => %{"phase" => phase}}} when phase in ["Failed", "Unknown"] ->
        {:error, {:pod_terminal, phase}}

      {:ok, _} ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(1000)
          poll_ready(namespace, name, deadline)
        else
          {:error, :pod_not_ready}
        end

      {:error, :not_found} ->
        {:error, :pod_not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ── kubectl ────────────────────────────────────────────────────────────

  defp kubectl(args, opts) do
    timeout = Keyword.get(opts, :timeout, @kubectl_timeout_ms)

    MuonTrap.cmd("kubectl", args,
      stderr_to_stdout: true,
      into: "",
      timeout: timeout
    )
  end

  # ── helpers ────────────────────────────────────────────────────────────

  defp sandbox_name(sandbox_id) do
    "glossia-sb-" <> String.replace(sandbox_id, "-", "")
  end

  defp sandbox_path(path) do
    if String.starts_with?(path, "/") do
      path
    else
      Path.join(configured(:repo_path, @default_repo_path), path)
    end
  end

  defp shell_wrap(cwd, env, argv) do
    env_prefix =
      env
      |> Enum.map(fn {k, v} -> "#{k}=#{shell_escape(to_string(v))}" end)
      |> Enum.join(" ")

    command = Enum.map_join(argv, " ", &shell_escape/1)

    ["/bin/sh", "-c", "cd #{shell_escape(cwd)} && #{env_prefix} #{command}"]
  end

  defp shell_escape(str) do
    "'" <> String.replace(str, "'", "'\"'\"'") <> "'"
  end

  defp split_command(command) when is_binary(command) do
    if String.contains?(command, ["|", ";", "&", "\n", ">", "<", "`"]) do
      {:error, :shell_syntax_not_supported}
    else
      {:ok, String.split(command, ~r/\s+/, trim: true)}
    end
  end

  defp ensure_safe_path(path) do
    cond do
      String.contains?(path, "..") -> {:error, :path_outside_sandbox}
      String.starts_with?(path, "/etc") -> {:error, :path_outside_sandbox}
      String.starts_with?(path, "/proc") -> {:error, :path_outside_sandbox}
      true -> :ok
    end
  end

  defp configured(key, default) do
    :glossia
    |> Application.get_env(Glossia.Sandbox, [])
    |> Keyword.get(key, default)
  end

  # ── agent session ──────────────────────────────────────────────────────

  defp run_agent_session(sandbox_id, caller, opts) do
    project_id = Keyword.fetch!(opts, :project_id)
    repository = Keyword.fetch!(opts, :repository)
    languages = Keyword.get(opts, :target_languages, [])
    harness = Keyword.get(opts, :harness, %{})
    timeout_ms = Keyword.get(opts, :timeout_ms, 660_000)

    payload =
      JSON.encode!(%{
        project_id: project_id,
        repository: repository,
        target_languages: languages,
        harness: harness,
        timeout_ms: timeout_ms
      })

    with :ok <- upload_file(sandbox_id, "/tmp/glossia/agent-input.json", payload),
         {:ok, result} <-
           execute(
             sandbox_id,
             "glossia-setup-harness /tmp/glossia/agent-input.json",
             timeout: timeout_ms
           ) do
      send(caller, {:agent_event, %{event_type: "agent_output", content: result["stdout"]}})

      if result["exitCode"] == 0 do
        send(caller, {:agent_done, :completed})
      else
        send(caller, {:agent_done, :failed})
      end
    else
      {:error, reason} ->
        Logger.warning("Kata agent session failed",
          sandbox_id: sandbox_id,
          reason: inspect(reason)
        )

        send(caller, {:agent_done, :failed})
    end
  end
end
