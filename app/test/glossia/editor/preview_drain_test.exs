defmodule Glossia.Editor.PreviewDrainTest do
  use ExUnit.Case, async: true

  alias Glossia.Editor.PreviewDrain

  test "shutdown waits for running previews and refuses new ones meanwhile" do
    supervisor = :"preview_drain_sup_#{System.unique_integer([:positive])}"
    start_supervised!({DynamicSupervisor, name: supervisor, strategy: :one_for_one})

    drain =
      start_supervised!({PreviewDrain, name: :"#{supervisor}_drain", supervisor: supervisor})

    {:ok, preview} =
      DynamicSupervisor.start_child(supervisor, %{
        id: :preview,
        start: {Agent, :start_link, [fn -> :running end]},
        restart: :temporary
      })

    refute PreviewDrain.draining?(supervisor)
    stopping = Task.async(fn -> GenServer.stop(drain, :shutdown, :infinity) end)

    Process.sleep(1_500)
    assert PreviewDrain.draining?(supervisor)
    assert Task.yield(stopping, 0) == nil

    :ok = DynamicSupervisor.terminate_child(supervisor, preview)
    assert Task.await(stopping, 5_000) == :ok
  end
end
