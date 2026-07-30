defmodule Glossia.Analytics.Ingestion do
  @moduledoc """
  Buffers a single enriched analytics event into ClickHouse.

  Mirrors the `Glossia.Ingestion` record_* helpers: encode one RowBinary row and
  cast it to the analytics buffer. The buffer batches rows and flushes
  asynchronously (see `Glossia.Ingestion.Buffer`), so this call never blocks on
  the network.
  """

  alias Glossia.Analytics.Event
  alias Glossia.Ingestion.Buffer

  @buffer Glossia.Analytics.EventBuffer

  @spec record_event(map()) :: :ok
  def record_event(attrs) do
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
    :ok
  end
end
