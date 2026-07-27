defmodule Glossia.TranslationSessions.ProgressTest do
  use ExUnit.Case, async: true

  alias Glossia.TranslationSessions.Progress

  test "distinguishes progress events from persisted session events" do
    assert Progress.progress_event?(%{type: "item_started", index: 0})
    refute Progress.progress_event?(%{event_type: "pr_created", content: "url"})
  end

  test "folds a run into per-file progress with turns and streamed text" do
    events = [
      %{type: "plan", total: 2},
      %{type: "item_started", index: 0, output_path: "es/a.md", locale: "es"},
      %{type: "item_event", index: 0, event: %{type: "turn_start"}},
      %{type: "item_event", index: 0, event: %{type: "text", text: "Hola"}},
      %{type: "item_event", index: 0, event: %{type: "text", text: ", mundo"}},
      %{type: "item_event", index: 0, event: %{type: "segment_output", text: "Hola, mundo"}},
      %{type: "item_event", index: 0, event: %{type: "translation_output", text: "Hola, mundo"}},
      %{type: "item_completed", index: 0},
      %{type: "item_started", index: 1, output_path: "ja/a.md", locale: "ja"},
      %{type: "item_event", index: 1, event: %{type: "turn_start"}},
      %{type: "item_failed", index: 1, reason: "boom"}
    ]

    state = Progress.fold(events)

    assert state.total == 2
    [first, second] = Progress.items(state)

    assert first.output_path == "es/a.md"
    assert first.status == :done
    assert first.turns == 1
    assert first.text == "Hola, mundo"

    assert second.status == :failed
    assert second.reason.kind == "translation-failed"
    assert second.reason.scope == "item"

    assert Progress.summary(state) == %{total: 2, skipped: 0, done: 1, failed: 1, running: 0}
  end

  test "keeps the previous preview visible until the next segment starts streaming" do
    state =
      Progress.fold([
        %{type: "item_started", index: 0, output_path: "ja/a.md", locale: "ja"},
        %{type: "item_event", index: 0, event: %{type: "attempt_start", attempt: 1}},
        %{type: "item_event", index: 0, event: %{type: "text", text: "first attempt"}},
        %{type: "item_event", index: 0, event: %{type: "attempt_start", attempt: 2}},
        %{type: "item_event", index: 0, event: %{type: "segment_start", index: 1, count: 3}}
      ])

    assert [%{text: "first attempt", replace_text_on_next_chunk: true}] =
             Progress.items(state)

    state =
      Progress.apply_event(state, %{
        type: "item_event",
        index: 0,
        event: %{type: "text", text: "current segment"}
      })

    assert [%{text: "current segment", replace_text_on_next_chunk: false}] =
             Progress.items(state)
  end

  test "a new plan clears progress left by a retried run" do
    state =
      Progress.fold([
        %{type: "plan", total: 2},
        %{type: "item_started", index: 0, output_path: "de/a.md", locale: "de"},
        %{type: "item_failed", index: 0, reason: "first attempt"},
        %{type: "item_started", index: 1, output_path: "es/a.md", locale: "es"},
        %{type: "plan", total: 2},
        %{type: "item_started", index: 0, output_path: "de/a.md", locale: "de"}
      ])

    assert [%{index: 0, status: :running, turns: 0}] = Progress.items(state)
    assert Progress.summary(state) == %{total: 2, skipped: 0, done: 0, failed: 0, running: 1}
  end

  test "counts skipped items" do
    state =
      Progress.fold([
        %{type: "plan", total: 1},
        %{type: "item_skipped", index: 0}
      ])

    assert Progress.summary(state).skipped == 1
  end

  test "recovers the plan total from a file event" do
    state =
      Progress.apply_event(Progress.new(), %{
        type: "item_started",
        index: 0,
        total: 6,
        output_path: "de/a.md",
        locale: "de"
      })

    assert Progress.summary(state) == %{total: 6, skipped: 0, done: 0, failed: 0, running: 1}
  end
end
