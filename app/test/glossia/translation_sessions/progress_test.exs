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
      %{type: "item_completed", index: 0, file_ref: "glossia/translate-source"},
      %{type: "item_started", index: 1, output_path: "ja/a.md", locale: "ja"},
      %{type: "item_event", index: 1, event: %{type: "turn_start"}},
      %{type: "item_failed", index: 1, reason: "boom"}
    ]

    state = Progress.fold(events)

    assert state.total == 2
    [first, second] = Progress.items(state)

    assert first.output_path == "es/a.md"
    assert first.status == :done
    assert first.file_ref == "glossia/translate-source"
    assert first.turns == 1
    assert first.text == "Hola, mundo"

    assert second.status == :failed
    assert second.reason.kind == "translation-failed"
    assert second.reason.scope == "item"

    assert Progress.summary(state) == %{
             total: 2,
             checked: 0,
             needs_translation: 2,
             assessed?: false,
             skipped: 0,
             done: 1,
             failed: 1,
             running: 0
           }
  end

  test "keeps completed segments visible while the next segment streams" do
    state =
      Progress.fold([
        %{type: "item_started", index: 0, output_path: "ja/a.md", locale: "ja"},
        %{type: "item_event", index: 0, event: %{type: "attempt_start", attempt: 1}},
        %{
          type: "item_event",
          index: 0,
          event: %{type: "segment_start", index: 1, count: 3, kind: "frontmatter"}
        },
        %{type: "item_event", index: 0, event: %{type: "text", text: "front matter"}},
        %{
          type: "item_event",
          index: 0,
          event: %{type: "segment_output", text: "front matter"}
        },
        %{
          type: "item_event",
          index: 0,
          event: %{type: "segment_start", index: 2, count: 3, kind: "content"}
        }
      ])

    assert [
             %{
               text: "front matter",
               completed_segments: [
                 %{count: 3, index: 1, kind: "frontmatter", text: "front matter"}
               ],
               segment_index: 2,
               segment_count: 3,
               segment_kind: "content"
             }
           ] =
             Progress.items(state)

    state =
      Progress.apply_event(state, %{
        type: "item_event",
        index: 0,
        event: %{type: "text", text: ""}
      })

    assert [%{text: "front matter"}] = Progress.items(state)

    state =
      Progress.apply_event(state, %{
        type: "item_event",
        index: 0,
        event: %{type: "text", text: "current segment"}
      })

    assert [%{text: "front matter\n\ncurrent segment"}] =
             Progress.items(state)
  end

  test "a validation retry replaces the previous attempt when new output arrives" do
    state =
      Progress.fold([
        %{type: "item_started", index: 0, output_path: "ja/a.md", locale: "ja"},
        %{type: "item_event", index: 0, event: %{type: "attempt_start", attempt: 1}},
        %{type: "item_event", index: 0, event: %{type: "segment_start", index: 1, count: 1}},
        %{type: "item_event", index: 0, event: %{type: "text", text: "invalid output"}},
        %{type: "item_event", index: 0, event: %{type: "attempt_start", attempt: 2}}
      ])

    assert [%{text: "invalid output", replace_text_on_next_chunk: true}] =
             Progress.items(state)

    state =
      Progress.apply_event(state, %{
        type: "item_event",
        index: 0,
        event: %{type: "text", text: "corrected output"}
      })

    assert [%{text: "corrected output", replace_text_on_next_chunk: false}] =
             Progress.items(state)
  end

  test "a duplicate plan keeps progress already reported for its run" do
    state =
      Progress.fold([
        %{type: "plan", total: 2},
        %{type: "item_started", index: 0, output_path: "de/a.md", locale: "de"},
        %{type: "item_failed", index: 0, reason: "first attempt"},
        %{type: "item_started", index: 1, output_path: "es/a.md", locale: "es"},
        %{type: "plan", total: 2},
        %{type: "item_started", index: 0, output_path: "de/a.md", locale: "de"}
      ])

    assert [
             %{index: 0, status: :running, output_path: "de/a.md"},
             %{index: 1, status: :running, output_path: "es/a.md"}
           ] = Progress.items(state)

    assert Progress.summary(state) == %{
             total: 2,
             checked: 0,
             needs_translation: 2,
             assessed?: false,
             skipped: 0,
             done: 0,
             failed: 0,
             running: 2
           }
  end

  test "counts per-file skips reported by a runner from an earlier release" do
    state =
      Progress.fold([
        %{type: "plan", total: 1},
        %{type: "item_skipped", index: 0}
      ])

    assert Progress.summary(state).skipped == 1
  end

  test "tracks how far the plan assessment has come" do
    state =
      Progress.fold([
        %{type: "plan", total: 231},
        %{type: "plan_progress", checked: 25, total: 231},
        %{type: "plan_progress", checked: 50, total: 231}
      ])

    summary = Progress.summary(state)

    assert summary.checked == 50
    assert summary.total == 231
    refute summary.assessed?
  end

  test "shows a file that failed before it started" do
    # The plan assessment can fail a file before it announces itself, such as
    # when its source cannot be read. The row still has to appear.
    state =
      Progress.fold([
        %{type: "plan", total: 1},
        %{
          type: "item_failed",
          index: 0,
          total: 1,
          output_path: "de/a.md",
          reason: %{kind: "source-unreadable", scope: "item"}
        }
      ])

    assert [%{index: 0, status: :failed, output_path: "de/a.md", reason: reason}] =
             Progress.items(state)

    assert reason.kind == "source-unreadable"
    assert Progress.summary(state).failed == 1
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

    assert Progress.summary(state) == %{
             total: 6,
             checked: 0,
             needs_translation: 6,
             assessed?: false,
             skipped: 0,
             done: 0,
             failed: 0,
             running: 1
           }
  end

  test "records the number of files that need model work after checking locks" do
    state =
      Progress.fold([
        %{type: "plan", total: 231},
        %{type: "plan_assessed", total: 231, needs_translation: 1, up_to_date: 230}
      ])

    assert Progress.summary(state) == %{
             total: 231,
             checked: 0,
             needs_translation: 1,
             assessed?: true,
             skipped: 230,
             done: 0,
             failed: 0,
             running: 0
           }
  end

  describe "retained reasoning" do
    defp reasoning_after(chunks) do
      [
        %{type: "item_started", index: 0, total: 1, output_path: "a.md", locale: "de"}
        | Enum.map(chunks, &%{type: "item_event", index: 0, event: %{type: "thinking", text: &1}})
      ]
      |> Progress.fold()
      |> Progress.items()
      |> hd()
      |> Map.fetch!(:reasoning)
    end

    test "keeps the newest reasoning rather than the oldest" do
      reasoning = reasoning_after([String.duplicate("old ", 2_000), "the newest thought"])

      assert String.ends_with?(reasoning, "the newest thought")
      assert String.length(reasoning) <= 4_000
    end

    # Graphemes alone do not bound memory: one can carry an unbounded run of
    # combining marks, so a byte ceiling backs the character one up.
    test "bounds pathological graphemes by bytes as well as by character count" do
      grapheme = "a" <> String.duplicate("\u0301", 200)
      reasoning = reasoning_after([String.duplicate(grapheme, 500)])

      assert String.length(reasoning) <= 4_000
      assert byte_size(reasoning) <= 16_000
    end

    test "never cuts a character in half" do
      reasoning = reasoning_after([String.duplicate("日本語のテキスト ", 3_000)])

      assert String.valid?(reasoning)
      assert byte_size(reasoning) <= 16_000
    end
  end

  describe "sequence handling" do
    test "ignores an event the state has already folded" do
      state =
        Progress.new()
        |> Progress.apply_event(%{type: "plan", total: 3, seq: 1})
        |> Progress.apply_event(%{type: "item_skipped", seq: 2})

      assert state.skipped == 1

      # The same event redelivered, which is what a viewer sees when it
      # subscribes before reading the persisted prefix.
      assert Progress.apply_event(state, %{type: "item_skipped", seq: 2}).skipped == 1
    end

    test "folds an event the state has not seen" do
      state =
        Progress.new()
        |> Progress.apply_event(%{type: "item_skipped", seq: 2})
        |> Progress.apply_event(%{type: "item_skipped", seq: 3})

      assert state.skipped == 2
      assert state.seq == 3
    end

    test "an event without a sequence still folds" do
      assert Progress.apply_event(Progress.new(), %{type: "plan", total: 4}).total == 4
    end

    test "a new run resets the files while keeping the sequence climbing" do
      state =
        Progress.new()
        |> Progress.apply_event(%{type: "plan", total: 1, seq: 1})
        |> Progress.apply_event(%{type: "item_started", index: 0, output_path: "es/a.md", seq: 2})
        |> Progress.apply_event(%{type: "run_started", seq: 3})

      assert Progress.items(state) == []
      assert state.total == 0
      assert state.seq == 3

      # The second run's events must still land rather than being taken for
      # replays of the first.
      state =
        Progress.apply_event(state, %{
          type: "item_started",
          index: 0,
          output_path: "ja/a.md",
          seq: 4
        })

      assert [%{output_path: "ja/a.md"}] = Progress.items(state)
    end
  end

  describe "durability" do
    test "only the events that shape the panel are worth persisting" do
      assert Progress.durable_event?(%{type: "plan", total: 1})
      assert Progress.durable_event?(%{type: "item_started", index: 0})
      assert Progress.durable_event?(%{type: "item_completed", index: 0})
      assert Progress.durable_event?(%{type: "item_failed", index: 0})

      # A re-run's reset has to be written down too, or a viewer folding the
      # whole history would merge both attempts into one panel.
      assert Progress.durable_event?(%{type: "run_started"})

      # Thousands per file. These stay on the live stream.
      refute Progress.durable_event?(%{type: "item_event", index: 0, event: %{type: "text"}})
    end

    test "decodes a payload that round-tripped through JSON" do
      decoded =
        Progress.decode(%{
          "type" => "item_started",
          "seq" => 7,
          "index" => 2,
          "output_path" => "es/a.md",
          "locale" => "es",
          "unexpected" => "dropped"
        })

      assert decoded == %{
               type: "item_started",
               seq: 7,
               index: 2,
               output_path: "es/a.md",
               locale: "es"
             }
    end

    test "folds decoded payloads back into the same state" do
      payloads = [
        %{"type" => "plan", "total" => 2, "seq" => 1},
        %{"type" => "item_started", "index" => 0, "output_path" => "es/a.md", "seq" => 2},
        %{"type" => "item_completed", "index" => 0, "file_ref" => "ref", "seq" => 3},
        %{"type" => "item_started", "index" => 1, "output_path" => "ja/a.md", "seq" => 4},
        %{
          "type" => "item_failed",
          "index" => 1,
          "reason" => %{"kind" => "provider-timeout"},
          "seq" => 5
        }
      ]

      state = payloads |> Enum.map(&Progress.decode/1) |> Progress.fold()

      assert state.total == 2
      assert %{done: 1, failed: 1} = Progress.summary(state)
      [first, second] = Progress.items(state)
      assert first.status == :done
      assert first.file_ref == "ref"
      assert second.status == :failed
      assert second.reason.kind == "provider-timeout"
    end
  end
end
