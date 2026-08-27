defmodule Glossia.TranslationSessions.ProgressCacheTest do
  use ExUnit.Case, async: true

  alias Glossia.TranslationSessions.ProgressCache

  setup do
    name = :"progress_cache_#{:erlang.unique_integer([:positive])}"
    start_supervised!({ProgressCache, name: name})
    %{cache: name}
  end

  test "retains folded progress for a reconnecting viewer", %{cache: cache} do
    session_id = Ecto.UUID.generate()

    ProgressCache.apply_event(session_id, %{type: "plan", total: 1}, cache)

    ProgressCache.apply_event(
      session_id,
      %{type: "item_started", index: 0, output_path: "de/example.md", locale: "de"},
      cache
    )

    assert %{total: 1} = ProgressCache.get(session_id, cache)

    assert [%{output_path: "de/example.md", status: :running}] =
             ProgressCache.get(session_id, cache) |> Glossia.TranslationSessions.Progress.items()
  end

  test "drops a session's progress when its run restarts", %{cache: cache} do
    session_id = Ecto.UUID.generate()
    ProgressCache.apply_event(session_id, %{type: "plan", total: 1}, cache)

    assert :ok = ProgressCache.clear(session_id, cache)
    assert %{total: 0, items: %{}} = ProgressCache.get(session_id, cache)
  end
end
