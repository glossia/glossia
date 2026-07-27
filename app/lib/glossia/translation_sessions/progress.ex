defmodule Glossia.TranslationSessions.Progress do
  @moduledoc """
  Folds the live progress events broadcast by
  `Glossia.Translations.RepositoryRun` into a renderable state for the
  translation LiveView: overall totals plus, per file, its status, the number of
  LLM turns taken, and the streamed output so far.

  Progress events are distinguished from persisted session events by their
  top-level `:type` key.
  """

  alias Glossia.Translations.Failure

  @type item :: %{
          index: non_neg_integer(),
          output_path: String.t() | nil,
          locale: String.t() | nil,
          status: :running | :done | :failed,
          turns: non_neg_integer(),
          text: String.t(),
          replace_text_on_next_chunk: boolean(),
          reason: Failure.t() | nil
        }

  @type t :: %{
          total: non_neg_integer(),
          skipped: non_neg_integer(),
          items: %{optional(non_neg_integer()) => item()}
        }

  @doc "An empty progress state."
  def new, do: %{total: 0, skipped: 0, items: %{}}

  @doc "Whether `event` is a RepositoryRun progress event (vs a persisted session event)."
  def progress_event?(%{type: type}) when is_binary(type), do: true
  def progress_event?(_event), do: false

  @doc "Folds a single progress event into the state."
  def apply_event(_state, %{type: "plan", total: total}), do: %{new() | total: total}

  def apply_event(state, %{type: "item_skipped"}), do: %{state | skipped: state.skipped + 1}

  def apply_event(state, %{type: "item_started", index: index} = event) do
    item = %{
      index: index,
      output_path: event[:output_path],
      locale: event[:locale],
      status: :running,
      turns: 0,
      text: "",
      replace_text_on_next_chunk: false,
      reason: nil
    }

    %{
      state
      | total: max(state.total, event[:total] || 0),
        items: Map.put(state.items, index, item)
    }
  end

  def apply_event(state, %{type: "item_event", index: index, event: turn}) do
    update_item(state, index, &apply_turn(&1, turn))
  end

  def apply_event(state, %{type: "item_completed", index: index}) do
    update_item(state, index, &%{&1 | status: :done})
  end

  def apply_event(state, %{type: "item_failed", index: index} = event) do
    update_item(
      state,
      index,
      &%{&1 | status: :failed, reason: Failure.normalize(event[:reason])}
    )
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

    %{
      total: state.total,
      skipped: state.skipped,
      done: Enum.count(items, &(&1.status == :done)),
      failed: Enum.count(items, &(&1.status == :failed)),
      running: Enum.count(items, &(&1.status == :running))
    }
  end

  defp apply_turn(item, %{type: "text", text: text}) do
    text = to_string(text)

    if item.replace_text_on_next_chunk do
      %{item | text: text, replace_text_on_next_chunk: false}
    else
      %{item | text: item.text <> text}
    end
  end

  defp apply_turn(item, %{type: type}) when type in ["attempt_start", "segment_start"],
    do: %{item | replace_text_on_next_chunk: true}

  defp apply_turn(item, %{type: type, text: text})
       when type in ["segment_output", "translation_output"],
       do: %{item | text: to_string(text), replace_text_on_next_chunk: false}

  defp apply_turn(item, %{type: "turn_start"}), do: %{item | turns: item.turns + 1}
  defp apply_turn(item, _turn), do: item

  defp update_item(state, index, fun) do
    case Map.get(state.items, index) do
      nil -> state
      item -> %{state | items: Map.put(state.items, index, fun.(item))}
    end
  end
end
