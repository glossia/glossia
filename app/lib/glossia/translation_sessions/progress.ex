defmodule Glossia.TranslationSessions.Progress do
  @moduledoc """
  Folds the live progress events broadcast by
  `Glossia.Translations.RepositoryRun` into a renderable state for the
  translation LiveView: overall totals plus, per file, its status, the number of
  language model calls made, and the streamed output so far.

  A reasoning model streams its thinking long before it writes any translation,
  and on a small model that can be the entire response. The tail of that
  reasoning is kept alongside the output so a running file shows what the model
  is doing rather than an empty box.

  Progress events are distinguished from persisted session events by their
  top-level `:type` key.
  """

  alias Glossia.Translations.Failure

  @thinking_preview_chars 2_000

  @type item :: %{
          index: non_neg_integer(),
          output_path: String.t() | nil,
          locale: String.t() | nil,
          status: :running | :done | :failed,
          turns: non_neg_integer(),
          text: String.t(),
          thinking: String.t(),
          completed_text: String.t(),
          current_segment_text: String.t(),
          replace_text_on_next_chunk: boolean(),
          segment_index: pos_integer() | nil,
          segment_count: pos_integer() | nil,
          segment_kind: String.t() | nil,
          file_ref: String.t() | nil,
          reason: Failure.t() | nil
        }

  @type t :: %{
          total: non_neg_integer(),
          checked: non_neg_integer(),
          needs_translation: non_neg_integer() | nil,
          skipped: non_neg_integer(),
          items: %{optional(non_neg_integer()) => item()}
        }

  @doc "An empty progress state."
  def new, do: %{total: 0, checked: 0, needs_translation: nil, skipped: 0, items: %{}}

  @doc "Whether `event` is a RepositoryRun progress event (vs a persisted session event)."
  def progress_event?(%{type: type}) when is_binary(type), do: true
  def progress_event?(_event), do: false

  @doc "Folds a single progress event into the state."
  def apply_event(_state, %{type: "plan", total: total}), do: %{new() | total: total}

  def apply_event(state, %{type: "plan_progress", checked: checked} = event) do
    %{
      state
      | total: max(state.total, event[:total] || 0),
        checked: max(state.checked, checked)
    }
  end

  def apply_event(
        state,
        %{type: "plan_assessed", needs_translation: needs_translation, up_to_date: up_to_date} =
          event
      ) do
    %{
      state
      | total: max(state.total, event[:total] || 0),
        needs_translation: needs_translation,
        skipped: up_to_date
    }
  end

  # A runner from an earlier release reports up-to-date files one at a time
  # instead of as a single `plan_assessed` count. Kept so a rolling deploy still
  # folds a correct summary.
  def apply_event(state, %{type: "item_skipped"}), do: %{state | skipped: state.skipped + 1}

  def apply_event(state, %{type: "item_started", index: index} = event),
    do: put_item(state, index, event)

  def apply_event(state, %{type: "item_event", index: index, event: turn}) do
    update_item(state, index, &apply_turn(&1, turn))
  end

  def apply_event(state, %{type: "item_completed", index: index} = event) do
    update_item(state, index, &%{&1 | status: :done, file_ref: event[:file_ref]})
  end

  def apply_event(state, %{type: "item_failed", index: index} = event) do
    state
    |> put_new_item(index, event)
    |> update_item(index, &%{&1 | status: :failed, reason: Failure.normalize(event[:reason])})
  end

  def apply_event(state, _event), do: state

  @doc "Folds a list of events into a fresh state."
  def fold(events), do: Enum.reduce(events, new(), &flip_apply/2)

  defp flip_apply(event, state), do: apply_event(state, event)

  @doc "Items ordered by their planned index."
  def items(state), do: state.items |> Map.values() |> Enum.sort_by(& &1.index)

  @doc "Counts of items by status plus skipped."
  def summary(state) do
    items = Map.values(state.items)
    needs_translation = state.needs_translation || max(state.total - state.skipped, 0)

    %{
      total: state.total,
      checked: state.checked,
      needs_translation: needs_translation,
      assessed?: not is_nil(state.needs_translation),
      skipped: state.skipped,
      done: Enum.count(items, &(&1.status == :done)),
      failed: Enum.count(items, &(&1.status == :failed)),
      running: Enum.count(items, &(&1.status == :running))
    }
  end

  defp apply_turn(item, %{type: "text", text: text}) do
    text = to_string(text)

    cond do
      text == "" ->
        item

      item.replace_text_on_next_chunk ->
        %{
          item
          | text: text,
            completed_text: "",
            current_segment_text: text,
            replace_text_on_next_chunk: false
        }

      true ->
        current_segment_text = item.current_segment_text <> text

        %{
          item
          | text: join_preview(item.completed_text, current_segment_text),
            current_segment_text: current_segment_text
        }
    end
  end

  defp apply_turn(item, %{type: "thinking", text: text}) do
    %{item | thinking: append_thinking(item.thinking, to_string(text))}
  end

  defp apply_turn(item, %{type: "attempt_start"}) do
    %{
      item
      | completed_text: "",
        current_segment_text: "",
        thinking: "",
        replace_text_on_next_chunk: true,
        segment_index: nil,
        segment_count: nil,
        segment_kind: nil
    }
  end

  defp apply_turn(item, %{type: "segment_start"} = event) do
    %{
      item
      | current_segment_text: "",
        thinking: "",
        segment_index: event[:index],
        segment_count: event[:count],
        segment_kind: event[:kind]
    }
  end

  defp apply_turn(item, %{type: "segment_output", text: text}) do
    completed_text =
      if item.replace_text_on_next_chunk do
        to_string(text)
      else
        join_preview(item.completed_text, to_string(text))
      end

    %{
      item
      | text: completed_text,
        completed_text: completed_text,
        current_segment_text: "",
        thinking: "",
        replace_text_on_next_chunk: false
    }
  end

  defp apply_turn(item, %{type: "translation_output", text: text}) do
    text = to_string(text)

    %{
      item
      | text: text,
        completed_text: text,
        current_segment_text: "",
        thinking: "",
        replace_text_on_next_chunk: false
    }
  end

  defp apply_turn(item, %{type: "turn_start"}), do: %{item | turns: item.turns + 1}
  defp apply_turn(item, _turn), do: item

  # Only the tail is kept: reasoning runs to thousands of chunks, and what a
  # viewer needs is the sentence the model is writing now.
  defp append_thinking(existing, ""), do: existing

  defp append_thinking(existing, chunk) do
    combined = existing <> chunk
    length = String.length(combined)

    if length > @thinking_preview_chars do
      String.slice(combined, length - @thinking_preview_chars, @thinking_preview_chars)
    else
      combined
    end
  end

  defp join_preview("", right), do: right
  defp join_preview(left, ""), do: left
  defp join_preview(left, right), do: left <> "\n\n" <> right

  defp update_item(state, index, fun) do
    case Map.get(state.items, index) do
      nil -> state
      item -> %{state | items: Map.put(state.items, index, fun.(item))}
    end
  end

  defp put_item(state, index, event) do
    item = %{
      index: index,
      output_path: event[:output_path],
      locale: event[:locale],
      status: :running,
      turns: 0,
      text: "",
      thinking: "",
      completed_text: "",
      current_segment_text: "",
      replace_text_on_next_chunk: false,
      segment_index: nil,
      segment_count: nil,
      segment_kind: nil,
      file_ref: nil,
      reason: nil
    }

    %{
      state
      | total: max(state.total, event[:total] || 0),
        items: Map.put(state.items, index, item)
    }
  end

  # A file can fail before it ever starts, such as when its source cannot be
  # read while the plan is assessed. Materialize the row so the failure is
  # visible instead of being dropped for an item that never announced itself.
  defp put_new_item(state, index, event) do
    if Map.has_key?(state.items, index), do: state, else: put_item(state, index, event)
  end
end
