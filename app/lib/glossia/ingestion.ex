defmodule Glossia.Ingestion do
  @moduledoc """
  Context for ingesting and querying ClickHouse data beyond audit events.
  """

  alias Glossia.Ingestion.{Buffer, SetupEvent, TranslationEvent}
  alias Glossia.ClickHouseRepo

  import Ecto.Query

  @setup_event_buffer Glossia.Ingestion.SetupEventBuffer
  @translation_event_buffer Glossia.Ingestion.TranslationEventBuffer

  def record_setup_event(project_id, sequence, event_type, content, metadata \\ "") do
    buffer_opts = SetupEvent.buffer_opts()

    row = [
      Uniq.UUID.uuid7(:raw),
      to_string(project_id),
      sequence,
      event_type,
      content || "",
      metadata || ""
    ]

    row_binary = Ch.RowBinary.encode_row(row, buffer_opts.encoding_types)
    Buffer.insert(@setup_event_buffer, row_binary)
  end

  def list_setup_events(project_id) do
    from(e in "setup_events",
      where: e.project_id == ^to_string(project_id),
      order_by: [asc: e.sequence],
      select: %{
        id: e.id,
        project_id: e.project_id,
        sequence: e.sequence,
        event_type: e.event_type,
        content: e.content,
        metadata: e.metadata,
        inserted_at: e.inserted_at
      }
    )
    |> ClickHouseRepo.all()
  end

  def list_setup_events(project_id, after_sequence: seq) do
    from(e in "setup_events",
      where: e.project_id == ^to_string(project_id) and e.sequence > ^seq,
      order_by: [asc: e.sequence],
      select: %{
        id: e.id,
        project_id: e.project_id,
        sequence: e.sequence,
        event_type: e.event_type,
        content: e.content,
        metadata: e.metadata,
        inserted_at: e.inserted_at
      }
    )
    |> ClickHouseRepo.all()
  end

  def max_setup_event_sequence(project_id) do
    from(e in "setup_events",
      where: e.project_id == ^to_string(project_id),
      select: max(e.sequence)
    )
    |> ClickHouseRepo.one() || 0
  end

  # --- Translation session events ---

  def record_translation_event(translation_id, sequence, event_type, content, metadata \\ "") do
    buffer_opts = TranslationEvent.buffer_opts()

    row = [
      Uniq.UUID.uuid7(:raw),
      to_string(translation_id),
      sequence,
      event_type,
      content || "",
      metadata || ""
    ]

    row_binary = Ch.RowBinary.encode_row(row, buffer_opts.encoding_types)
    Buffer.insert(@translation_event_buffer, row_binary)
  end

  def list_translation_events(translation_id) do
    from(e in "translation_session_events",
      where: e.session_id == ^to_string(translation_id),
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
end
