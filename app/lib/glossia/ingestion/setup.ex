defmodule Glossia.Ingestion.Setup do
  @moduledoc """
  Enterprise-side ClickHouse ingestion for the automated project setup flow.

  The community `Glossia.Ingestion` module no longer knows about
  setup events — that whole path lives here now. The buffer name and
  target table match what the old code used, so existing setup rows in
  ClickHouse are read back by the same schema.
  """

  alias Glossia.Ingestion.Buffer
  alias Glossia.ClickHouseRepo
  alias Glossia.IngestRepo
  alias Glossia.Ingestion.SetupEvent

  import Ecto.Query

  @setup_event_buffer Glossia.Ingestion.SetupEventBuffer

  def record_setup_event(project_id, sequence, event_type, content, metadata \\ "") do
    if write_through_repo?() do
      IngestRepo.insert_all(SetupEvent, [
        %{
          id: Uniq.UUID.uuid7(),
          project_id: to_string(project_id),
          sequence: sequence,
          event_type: event_type,
          content: content || "",
          metadata: metadata || ""
        }
      ])
    else
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

  defp write_through_repo? do
    :glossia
    |> Application.get_env(Glossia.Ingestion.Bufferable, [])
    |> Keyword.get(:write_through_repo, false)
  end
end
