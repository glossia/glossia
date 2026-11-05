defmodule Glossia.Editor.PreviewDrain do
  @moduledoc """
  Keeps a shutting-down node serving the app previews it already runs.

  A preview's setup, browser, and LiveView all live on the node that started
  it, so stopping that node mid-deploy would discard minutes of work. Started
  after the endpoints, this process is the first child stopped: it marks the
  node as draining, so new previews start elsewhere, and returns once every
  running preview has ended. Previews end on their own within
  `Glossia.Editor.Preview`'s absolute deadline, which bounds the wait. The pod's
  termination grace period must exceed `shutdown_ms/0`.
  """
  use GenServer

  @poll_ms 1_000
  @supervisor Glossia.Editor.Preview.Supervisor

  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      shutdown: shutdown_ms()
    }
  end

  # The longest a preview can live, plus a margin to clean up its sandbox.
  def shutdown_ms, do: Glossia.Editor.Preview.absolute_ms() + 30_000

  def draining?(supervisor \\ @supervisor),
    do: :persistent_term.get({__MODULE__, supervisor}, false)

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, Keyword.get(opts, :supervisor, @supervisor)}
  end

  @impl true
  def terminate(_reason, supervisor) do
    :persistent_term.put({__MODULE__, supervisor}, true)
    wait(supervisor)
  end

  defp wait(supervisor) do
    if Process.whereis(supervisor) && DynamicSupervisor.count_children(supervisor).active > 0 do
      Process.sleep(@poll_ms)
      wait(supervisor)
    else
      :ok
    end
  end
end
