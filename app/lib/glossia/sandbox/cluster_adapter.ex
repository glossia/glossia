defmodule Glossia.Sandbox.ClusterAdapter do
  @moduledoc """
  Cluster-backed sandbox adapter.

  Each sandbox is scheduled as a runner process with its own temporary working
  tree. In production and kind reproduction this uses FLAME's Kubernetes
  backend to create runner pods; in tests it can use FLAME's local backend.
  """

  @behaviour Glossia.Sandbox

  alias Glossia.Repo
  alias Glossia.Sandbox.ProcessRegistry
  alias Glossia.Sandboxes.Sandbox

  @impl true
  def create(params) when is_map(params) do
    create(params, &FLAME.place_child/3)
  end

  @doc false
  def create(params, place_child) when is_map(params) and is_function(place_child, 3) do
    sandbox_id = to_string(params[:id] || params["id"] || Ecto.UUID.generate())

    child_spec =
      {Glossia.Sandbox.Runner,
       sandbox_id: sandbox_id, root_path: params[:root_path] || params["root_path"]}

    case place_child.(Glossia.Flame.pool_name(), child_spec,
           timeout: boot_timeout(),
           link: false
         ) do
      {:ok, pid} ->
        :ok = ProcessRegistry.put(sandbox_id, pid)
        {:ok, owner_ref()}

      {:error, reason} ->
        {:error, normalize_start_error(reason)}
    end
  catch
    :exit, reason -> {:error, normalize_start_error(reason)}
  end

  @impl true
  def execute(sandbox_id, command, opts \\ []) do
    with {:ok, pid, _owner_node} <- fetch_runner(sandbox_id) do
      GenServer.call(pid, {:execute, command, opts}, call_timeout(opts))
    end
  catch
    :exit, {:timeout, _} -> {:error, :timeout}
    :exit, {:noproc, _} -> {:error, :not_found}
    :exit, reason -> {:error, reason}
  end

  @impl true
  def delete(sandbox_id) do
    with {:ok, pid, owner_node} <- fetch_runner(sandbox_id) do
      case GenServer.call(pid, :delete, 30_000) do
        :ok ->
          delete_runner_ref(sandbox_id, owner_node)
          :ok

        {:error, _reason} = error ->
          error
      end
    else
      {:error, reason} when reason in [:owner_unreachable, {:owner_unreachable, :nodedown}] ->
        {:error, :not_found}

      {:error, {:owner_unreachable, _reason}} ->
        {:error, :not_found}

      {:error, _reason} = error ->
        error
    end
  catch
    :exit, {:noproc, _} -> {:error, :not_found}
    :exit, reason -> {:error, reason}
  end

  @impl true
  def download_file(sandbox_id, path) do
    call_runner(sandbox_id, {:download_file, path})
  end

  @impl true
  def upload_file(sandbox_id, path, content) do
    call_runner(sandbox_id, {:upload_file, path, content})
  end

  @impl true
  def delete_file(sandbox_id, path) do
    call_runner(sandbox_id, {:delete_file, path})
  end

  @impl true
  def repo_path(sandbox_id) do
    call_runner(sandbox_id, :repo_path)
  end

  @impl true
  def start_agent_session(sandbox_id, caller, opts) when is_pid(caller) do
    Task.start(fn -> run_agent_session(sandbox_id, caller, opts) end)
  end

  defp run_agent_session(sandbox_id, caller, opts) do
    with {:ok, repo_path} <- repo_path(sandbox_id) do
      callbacks = %{
        execute_shell: fn command, command_opts ->
          execute_shell(sandbox_id, command, command_opts)
        end,
        upload_file: fn path, content -> upload_file(sandbox_id, path, content) end,
        download_file: fn path -> download_file(sandbox_id, path) end
      }

      opts = Keyword.put(opts, :repo_path, repo_path)

      case Glossia.Projects.SetupHarness.run(callbacks, caller, opts) do
        :ok -> send(caller, {:agent_done, :completed})
        {:error, _reason} -> send(caller, {:agent_done, :failed})
      end
    else
      _error -> send(caller, {:agent_done, :failed})
    end
  end

  defp call_runner(sandbox_id, message) do
    with {:ok, pid, _owner_node} <- fetch_runner(sandbox_id) do
      GenServer.call(pid, message, 30_000)
    end
  catch
    :exit, {:noproc, _} -> {:error, :not_found}
    :exit, reason -> {:error, reason}
  end

  defp execute_shell(sandbox_id, command, opts) do
    with {:ok, pid, _owner_node} <- fetch_runner(sandbox_id) do
      GenServer.call(pid, {:execute_shell, command, opts}, call_timeout(opts))
    end
  catch
    :exit, {:timeout, _} -> {:error, :timeout}
    :exit, {:noproc, _} -> {:error, :not_found}
    :exit, reason -> {:error, reason}
  end

  defp boot_timeout do
    :glossia
    |> Application.get_env(:flame, [])
    |> Keyword.get(:boot_timeout, 120_000)
  end

  defp normalize_start_error({:timeout, {FLAME.Pool, :place_child, _arguments}} = reason),
    do: {:sandbox_start_timeout, reason}

  defp normalize_start_error(reason), do: reason

  defp fetch_runner(sandbox_id) do
    case ProcessRegistry.fetch(sandbox_id) do
      {:ok, pid} ->
        {:ok, pid, node()}

      {:error, :not_found} ->
        with {:ok, owner_node} <- fetch_owner_node(sandbox_id),
             {:ok, pid} <- fetch_runner_from_owner(owner_node, sandbox_id) do
          {:ok, pid, owner_node}
        end
    end
  end

  defp fetch_runner_from_owner(owner_node, sandbox_id) when owner_node == node() do
    ProcessRegistry.fetch(sandbox_id)
  end

  defp fetch_runner_from_owner(owner_node, sandbox_id) do
    case :rpc.call(owner_node, ProcessRegistry, :fetch, [sandbox_id], 5_000) do
      {:ok, pid} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
      {:badrpc, reason} -> {:error, {:owner_unreachable, reason}}
    end
  end

  defp delete_runner_ref(sandbox_id, owner_node) when owner_node == node() do
    ProcessRegistry.delete(sandbox_id)
  end

  defp delete_runner_ref(sandbox_id, owner_node) do
    case :rpc.call(owner_node, ProcessRegistry, :delete, [sandbox_id], 5_000) do
      :ok -> :ok
      {:badrpc, _reason} -> :ok
    end
  end

  defp fetch_owner_node(sandbox_id) do
    with {:ok, id} <- Ecto.UUID.cast(sandbox_id),
         %Sandbox{backend_ref: backend_ref} <- Repo.get(Sandbox, id) do
      decode_owner_ref(backend_ref)
    else
      :error -> {:error, :not_found}
      nil -> {:error, :not_found}
    end
  end

  defp decode_owner_ref("cluster:" <> node_name) do
    {:ok, String.to_existing_atom(node_name)}
  rescue
    ArgumentError -> {:error, :owner_unreachable}
  end

  defp decode_owner_ref(_backend_ref), do: {:error, :not_found}

  defp owner_ref, do: "cluster:#{node()}"

  defp call_timeout(opts) do
    timeout =
      option(opts, :timeout_ms, Glossia.Sandbox.configured(:command_timeout_ms, 120_000))

    timeout + 1_000
  end

  defp option(opts, key, default) when is_list(opts) do
    case Keyword.fetch(opts, key) do
      {:ok, nil} -> default
      {:ok, value} -> value
      :error -> default
    end
  end

  defp option(_opts, _key, default), do: default
end
