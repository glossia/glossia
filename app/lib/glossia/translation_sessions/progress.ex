defmodule Glossia.TranslationSessions.Progress do
  @moduledoc """
  Folds the live progress events broadcast by
  `Glossia.Translations.RepositoryRun` into a renderable state for the
  translation LiveView: overall totals plus, per file, its status, the number of
  language model calls made, and the translated output so far.

  The user-facing contract contains only application-owned milestones: planning,
  starting a file or segment, accepting output, retrying, and completing. Model
  thinking is intentionally excluded. It is both too verbose to present well
  and not a stable data format for a progress interface.

  Progress events are distinguished from persisted session events by their
  top-level `:type` key.
  """

  alias Glossia.Translations.Failure

  @doc "An empty progress state."
  def new, do: %{total: 0, checked: 0, needs_translation: nil, skipped: 0, seq: 0, items: %{}}

  @doc "Whether `event` is a RepositoryRun progress event (vs a persisted session event)."
  def progress_event?(%{type: type}) when is_binary(type), do: true
  def progress_event?(_event), do: false

  # The events that shape the panel, and so the ones worth a row in Postgres.
  # Text chunks arrive thousands of times per file and are left to the live
  # stream: a viewer who joins late sees the file as running with the text it
  # has produced since they arrived, rather than a replayed transcript.
  @durable_types ~w(run_started plan plan_progress plan_assessed item_started item_completed item_failed item_cancelled item_skipped)

  @doc "Whether `event` is worth persisting so a later viewer can rebuild the panel."
  def durable_event?(%{type: type}), do: type in @durable_types
  def durable_event?(_event), do: false

  @doc """
  Restores an event that was persisted as JSON.

  Only the keys the fold reads are converted back to atoms, from a fixed list,
  so a payload written by a newer release cannot introduce atoms here.
  """
  def decode(%{} = payload) do
    Enum.reduce(
      ~w(
        type
        seq
        index
        total
        checked
        needs_translation
        up_to_date
        output_path
        locale
        file_ref
        output_preview
        model_calls
        reason
      )a,
      %{},
      fn key, acc ->
        case Map.fetch(payload, Atom.to_string(key)) do
          {:ok, value} -> Map.put(acc, key, value)
          :error -> acc
        end
      end
    )
  end

  @doc """
  Folds a single progress event into the state.

  Events carry a `seq` that is monotonic for the lifetime of the session, so one
  that has already been folded is ignored. That is what lets a viewer subscribe
  first and read the persisted prefix second without double-counting whatever
  arrived in between.
  """
  def apply_event(state, %{seq: seq} = event) when is_integer(seq) do
    if seq <= Map.get(state, :seq, 0) do
      state
    else
      state |> do_apply_event(event) |> Map.put(:seq, seq)
    end
  end

  def apply_event(state, event), do: do_apply_event(state, event)

  # A run announces itself before it plans anything. Folding this resets the
  # files from any earlier attempt while keeping `seq` climbing, so a viewer
  # holding the previous run's state adopts the new one instead of discarding
  # its events as stale.
  defp do_apply_event(state, %{type: "run_started"}), do: %{new() | seq: Map.get(state, :seq, 0)}

  # A plan begins a run. A duplicate plan from a reconnect or a delayed node
  # must not make already-visible file progress disappear.
  defp do_apply_event(%{items: items} = state, %{type: "plan", total: total})
       when map_size(items) > 0,
       do: %{state | total: max(state.total, total)}

  defp do_apply_event(state, %{type: "plan", total: total}),
    do: %{new() | total: total, seq: Map.get(state, :seq, 0)}

  defp do_apply_event(state, %{type: "plan_progress", checked: checked} = event) do
    %{
      state
      | total: max(state.total, event[:total] || 0),
        checked: max(state.checked, checked)
    }
  end

  defp do_apply_event(
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
  defp do_apply_event(state, %{type: "item_skipped"}), do: %{state | skipped: state.skipped + 1}

  defp do_apply_event(state, %{type: "item_started", index: index} = event),
    do: put_item(state, index, event)

  defp do_apply_event(state, %{type: "item_event", index: index, event: turn}) do
    update_item(state, index, &apply_turn(&1, turn))
  end

  defp do_apply_event(state, %{type: "item_completed", index: index} = event) do
    update_item(state, index, fn item ->
      output_preview =
        if is_binary(event[:output_preview]), do: event.output_preview, else: item.text

      model_calls = if is_integer(event[:model_calls]), do: event.model_calls, else: item.turns

      %{
        item
        | status: :done,
          file_ref: event[:file_ref] || item.file_ref,
          text: output_preview,
          completed_text: output_preview,
          current_segment_text: "",
          turns: model_calls
      }
    end)
  end

  defp do_apply_event(state, %{type: "item_failed", index: index} = event) do
    state
    |> put_new_item(index, event)
    |> update_item(index, fn item ->
      model_calls = if is_integer(event[:model_calls]), do: event.model_calls, else: item.turns
      %{item | status: :failed, reason: Failure.normalize(event[:reason]), turns: model_calls}
    end)
  end

  # A superseded or user-cancelled run leaves in-flight items in :running with no
  # more events coming from the pod behind it, so they stay running forever in
  # the fold. The session context emits one of these per running item at the
  # moment it cancels so the panel closes them out with a distinct status.
  defp do_apply_event(state, %{type: "item_cancelled", index: index} = event) do
    state
    |> put_new_item(index, event)
    |> update_item(index, fn item ->
      if item.status == :done or item.status == :failed do
        item
      else
        %{item | status: :cancelled, reason: event[:reason] || item.reason}
      end
    end)
  end

  defp do_apply_event(state, _event), do: state

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
      cancelled: Enum.count(items, &(&1.status == :cancelled)),
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

  defp apply_turn(item, %{type: "attempt_start"}) do
    %{
      item
      | completed_text: "",
        completed_segments: [],
        current_segment_text: "",
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
        segment_index: event[:index],
        segment_count: event[:count],
        segment_kind: event[:kind]
    }
  end

  defp apply_turn(item, %{type: "segment_output", text: text}) do
    text = to_string(text)

    completed_text =
      if item.replace_text_on_next_chunk do
        text
      else
        join_preview(item.completed_text, text)
      end

    completed_segments =
      case item.segment_index do
        nil ->
          item.completed_segments

        index ->
          item.completed_segments ++
            [
              %{
                index: index,
                count: item.segment_count,
                kind: item.segment_kind,
                text: text
              }
            ]
      end

    %{
      item
      | text: completed_text,
        completed_text: completed_text,
        completed_segments: completed_segments,
        current_segment_text: "",
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
        replace_text_on_next_chunk: false
    }
  end

  defp apply_turn(item, %{type: "turn_start"}), do: %{item | turns: item.turns + 1}
  defp apply_turn(item, _turn), do: item

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
      completed_text: "",
      completed_segments: [],
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
