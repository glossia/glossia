defmodule Glossia.Docs.SearchIndexer do
  @moduledoc false

  use GenServer

  require Logger

  @retry_after_ms :timer.minutes(1)

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @impl GenServer
  def init(:ok) do
    send(self(), :index)
    {:ok, nil}
  end

  @impl GenServer
  def handle_info(:index, state) do
    case Glossia.Docs.Search.ensure_indexed() do
      :ok ->
        {:noreply, state}

      {:error, reason} ->
        Logger.warning("Documentation search indexing failed: #{inspect(reason)}")
        Process.send_after(self(), :index, @retry_after_ms)
        {:noreply, state}
    end
  end
end
