defmodule GlossiaWeb.TranslationSnapshot do
  @moduledoc "The shared HTTP/native translation detail projection. No provider payloads or reasoning."

  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.Progress

  @session_fields ~w(id status commit_message commit_sha source_language target_languages translated_content_count inserted_at summary)a
  @item_fields ~w(index output_path locale status turns file_ref)a
  @max_items 500
  @items_budget 512_000
  @max_payload_bytes 1_000_000

  def detail(session) do
    progress = TranslationSessions.session_progress(session.id)
    project(session, progress, progress.seq)
  end

  def project(session, progress, durable_seq) do
    all_items = Progress.items(progress)

    {items, _bytes} =
      all_items
      |> Enum.take(@max_items)
      |> Enum.reduce({[], 0}, fn item, {items, bytes} ->
        item = Map.take(item, @item_fields)
        size = byte_size(JSON.encode!(item)) + 1

        if bytes + size <= @items_budget,
          do: {[item | items], bytes + size},
          else: {items, bytes}
      end)

    %{
      session: Map.take(session, @session_fields),
      progress: %{
        seq: durable_seq,
        summary: Progress.summary(progress),
        items: Enum.reverse(items),
        omitted_items: length(all_items) - length(items)
      }
    }
  end

  # Leave the existing session fields and complete summary intact. Refuse a
  # pathological session rather than silently truncate its provenance/counts.
  def bounded(snapshot) do
    if byte_size(JSON.encode!(snapshot)) <= @max_payload_bytes,
      do: {:ok, snapshot},
      else: {:error, "payload_too_large"}
  end
end
