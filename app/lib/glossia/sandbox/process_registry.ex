defmodule Glossia.Sandbox.ProcessRegistry do
  @moduledoc false

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def put(id, pid) when is_binary(id) and is_pid(pid) do
    GenServer.call(__MODULE__, {:put, id, pid})
  end

  def fetch(id) when is_binary(id) do
    GenServer.call(__MODULE__, {:fetch, id})
  end

  def delete(id) when is_binary(id) do
    GenServer.call(__MODULE__, {:delete, id})
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:put, id, pid}, _from, state) do
    state = demonitor_existing(state, id)
    ref = Process.monitor(pid)
    {:reply, :ok, Map.put(state, id, %{pid: pid, ref: ref})}
  end

  def handle_call({:fetch, id}, _from, state) do
    case Map.get(state, id) do
      %{pid: pid} -> {:reply, {:ok, pid}, state}
      nil -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:delete, id}, _from, state) do
    {:reply, :ok, demonitor_existing(state, id)}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state =
      Enum.reduce(state, state, fn
        {id, %{ref: ^ref}}, acc -> Map.delete(acc, id)
        {_id, _entry}, acc -> acc
      end)

    {:noreply, state}
  end

  defp demonitor_existing(state, id) do
    case Map.get(state, id) do
      %{ref: ref} ->
        Process.demonitor(ref, [:flush])
        Map.delete(state, id)

      nil ->
        state
    end
  end
end
