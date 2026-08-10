defmodule Glossia.Analytics.Ingestion do
  @moduledoc """
  Writes a single enriched analytics event to ClickHouse.

  In production, encodes one RowBinary row and casts it to the analytics
  buffer (`Glossia.Analytics.EventBuffer`). The buffer batches rows and flushes
  asynchronously (see `Glossia.Ingestion.Buffer`), so this call never blocks on
  the network.

  In tests, when `write_through_repo: true` is set on
  `Glossia.Ingestion.Bufferable`, the write goes directly through
  `Glossia.IngestRepo.insert_all/3` and bypasses the buffer, so the row is
  visible to the test's sandboxed connection immediately.
  """

  alias Glossia.Analytics.Event
  alias Glossia.Ingestion.Buffer
  alias Glossia.IngestRepo

  @buffer Glossia.Analytics.EventBuffer

  @spec record_event(map()) :: :ok
  def record_event(attrs) do
    if write_through_repo?() do
      %{fields: fields} = Event.buffer_opts()

      # `id` is generated here rather than supplied by the caller, exactly as
      # the buffer branch below does, and the same `to_string/1` coercions are
      # applied so both paths write identical rows.
      row =
        fields
        |> Enum.reject(&(&1 == :id))
        |> Map.new(fn field -> {field, Map.fetch!(attrs, field)} end)
        |> Map.merge(%{
          id: Uniq.UUID.uuid7(),
          project_id: to_string(attrs.project_id),
          session_id: to_string(attrs.session_id)
        })

      IngestRepo.insert_all(Event, [row])
    else
      buffer_opts = Event.buffer_opts()

      # IMPORTANT: this list must stay in schema field declaration order.
      row = [
        Uniq.UUID.uuid7(:raw),
        to_string(attrs.project_id),
        attrs.visitor_id,
        to_string(attrs.session_id),
        attrs.name,
        attrs.hostname,
        attrs.pathname,
        attrs.referrer,
        attrs.referrer_source,
        attrs.country_code,
        attrs.browser_language,
        attrs.served_locale,
        attrs.has_locale_gap,
        attrs.device,
        attrs.browser,
        attrs.os,
        attrs.screen_width,
        attrs.timezone
      ]

      row_binary = Ch.RowBinary.encode_row(row, buffer_opts.encoding_types)
      Buffer.insert(@buffer, row_binary)
    end

    :ok
  end

  defp write_through_repo? do
    :glossia
    |> Application.get_env(Glossia.Ingestion.Bufferable, [])
    |> Keyword.get(:write_through_repo, false)
  end
end
