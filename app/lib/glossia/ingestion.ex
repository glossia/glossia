defmodule Glossia.Ingestion do
  @moduledoc """
  Context for ingesting and querying ClickHouse data beyond audit events.
  """

  alias Glossia.Ingestion.{Buffer, TranslationSessionEvent}
  alias Glossia.ClickHouseRepo
  alias Glossia.IngestRepo

  import Ecto.Query

  @translation_session_event_buffer Glossia.Ingestion.TranslationSessionEventBuffer

  def record_translation_session_event(session_id, sequence, event_type, content, metadata \\ "") do
    if write_through_repo?() do
      IngestRepo.insert_all(TranslationSessionEvent, [
        %{
          id: Uniq.UUID.uuid7(),
          session_id: to_string(session_id),
          sequence: sequence,
          event_type: event_type,
          content: content || "",
          metadata: metadata || ""
        }
      ])
    else
      buffer_opts = TranslationSessionEvent.buffer_opts()

      row = [
        Uniq.UUID.uuid7(:raw),
        to_string(session_id),
        sequence,
        event_type,
        content || "",
        metadata || ""
      ]

      row_binary = Ch.RowBinary.encode_row(row, buffer_opts.encoding_types)
      Buffer.insert(@translation_session_event_buffer, row_binary)
    end
  end

  def list_translation_session_events(session_id) do
    from(e in "translation_session_events",
      where: e.session_id == ^to_string(session_id),
      order_by: [asc: e.sequence],
      select: %{
        id: e.id,
        session_id: e.session_id,
        sequence: e.sequence,
        event_type: e.event_type,
        content: e.content,
        metadata: e.metadata,
        inserted_at: e.inserted_at
      }
    )
    |> ClickHouseRepo.all()
  end

  def max_translation_session_event_sequence(session_id) do
    from(e in "translation_session_events",
      where: e.session_id == ^to_string(session_id),
      select: max(e.sequence)
    )
    |> ClickHouseRepo.one() || 0
  end

  defp write_through_repo? do
    :glossia
    |> Application.get_env(Glossia.Ingestion.Bufferable, [])
    |> Keyword.get(:write_through_repo, false)
  end
end
