defmodule Glossia.Sandbox.Reaper do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    interval_ms = Keyword.get(opts, :interval_ms, configured(:reaper_interval_ms, 60_000))

    state = %{
      enabled: configured(:enabled, true) and configured(:reaper_enabled, true),
      interval_ms: interval_ms,
      now_fun: Keyword.get(opts, :now_fun, &DateTime.utc_now/0)
    }

    if state.enabled, do: Process.send_after(self(), :reap, 0)

    {:ok, state}
  end

  @impl true
  def handle_info(:reap, state) do
    try do
      Glossia.Sandboxes.reap_expired_sandboxes(state.now_fun.())
    rescue
      exception ->
        Logger.warning("Sandbox reaper failed: #{Exception.message(exception)}")
    catch
      kind, reason ->
        Logger.warning("Sandbox reaper failed: #{inspect({kind, reason})}")
    after
      Process.send_after(self(), :reap, state.interval_ms)
    end

    {:noreply, state}
  end

  defp configured(key, default), do: Glossia.Sandbox.configured(key, default)
end
