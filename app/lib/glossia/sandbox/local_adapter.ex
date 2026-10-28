defmodule Glossia.Sandbox.LocalAdapter do
  @moduledoc """
  Host-local workspaces for trusted repositories in Community.

  File operations are restricted by `Glossia.Sandbox.Runner`, but setup commands
  run as the application user. A workspace is not a container or a sandbox for
  untrusted code.
  """

  @behaviour Glossia.Sandbox

  alias Glossia.Projects.SetupHarness
  alias Glossia.Sandbox.{ProcessRegistry, Runner}
  alias Glossia.Sandboxes

  @impl true
  def create(params) do
    id = to_string(params[:id] || params["id"] || Ecto.UUID.generate())
    spec = Supervisor.child_spec({Runner, sandbox_id: id}, restart: :temporary)

    with {:ok, pid} <- DynamicSupervisor.start_child(Glossia.Sandbox.Supervisor, spec),
         :ok <- ProcessRegistry.put(id, pid) do
      {:ok, Atom.to_string(node())}
    end
  end

  @impl true
  def execute(id, command, opts \\ []), do: call(id, {:execute, command, opts})

  @impl true
  def download_file(id, path), do: call(id, {:download_file, path})

  @impl true
  def upload_file(id, path, content), do: call(id, {:upload_file, path, content})

  @impl true
  def delete_file(id, path), do: call(id, {:delete_file, path})

  @impl true
  def repo_path(id), do: call(id, :repo_path)

  @impl true
  def delete(id) do
    call(id, :delete)
  end

  @impl true
  def start_agent_session(id, caller, opts) do
    with {:ok, repo_path} <- repo_path(id) do
      Task.start_link(fn ->
        callbacks = %{
          execute_shell: fn command, opts -> call(id, {:execute_shell, command, opts}) end,
          upload_file: &upload_file(id, &1, &2),
          download_file: &download_file(id, &1)
        }

        result = SetupHarness.run(callbacks, caller, Keyword.put(opts, :repo_path, repo_path))
        send(caller, {:agent_done, if(result == :ok, do: :completed, else: :failed)})
      end)
    end
  end

  defp call(id, message) do
    case ProcessRegistry.fetch(id) do
      {:ok, _pid} -> local_call(id, message)
      {:error, :not_found} -> call_owner(id, message)
    end
  end

  defp call_owner(id, message) do
    case Sandboxes.get_sandbox_by_id(id) do
      nil ->
        {:error, :not_found}

      %{backend_ref: owner} ->
        case Enum.find([node() | Node.list(:connected)], &(Atom.to_string(&1) == owner)) do
          nil -> {:error, :sandbox_owner_unavailable}
          owner_node when owner_node == node() -> local_call(id, message)
          owner_node -> remote_call(owner_node, id, message)
        end
    end
  end

  defp remote_call(owner, id, message) do
    :erpc.call(owner, __MODULE__, :local_call, [id, message], :infinity)
  catch
    :error, {:erpc, reason} -> {:error, {:sandbox_owner_unavailable, reason}}
  end

  # Called on the persisted owner only. A missing registry entry on another
  # replica is never evidence that this workspace has been deleted.
  @doc false
  def local_call(id, :delete) do
    case ProcessRegistry.fetch(id) do
      {:ok, pid} ->
        case GenServer.call(pid, :delete, :infinity) do
          :ok -> ProcessRegistry.delete(id)
          result -> result
        end

      {:error, :not_found} ->
        Runner.remove_workspace(id)
    end
  end

  def local_call(id, message) do
    with {:ok, pid} <- ProcessRegistry.fetch(id) do
      GenServer.call(pid, message, :infinity)
    end
  end
end
