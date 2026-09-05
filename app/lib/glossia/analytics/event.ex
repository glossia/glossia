defmodule Glossia.Analytics.Event do
  @moduledoc """
  ClickHouse event row for website analytics collected by the `@glossia/web` SDK.

  Each row is a single event (pageview or custom). Personally identifying inputs
  (IP address, User-Agent) are never stored: only server-derived aggregates land
  here. `visitor_id` is a daily-rotated HMAC and cannot be linked across days
  (see `Glossia.Analytics.Identity`).

  The localization columns are computed at ingestion time against the project's
  current target languages, so historical rows reflect the opportunity *as of
  the visit*:

    * `browser_language` - the visitor's most preferred normalized locale,
    * `served_locale` - the first supported target that matched, or `""`,
    * `has_locale_gap` - `1` when the visitor wanted a language the project does
      not serve.

  `inserted_at` is not a schema field: it is populated by the table default and
  therefore excluded from the RowBinary payload, mirroring `setup_events`.
  """

  use Ecto.Schema
  use Glossia.Ingestion.Bufferable

  @primary_key false

  # Field declaration order is significant: `Glossia.Analytics.Ingestion` builds
  # the RowBinary row list to match this order exactly.
  schema "analytics_events" do
    field :id, Ch, type: "UUID"
    field :project_id, Ch, type: "LowCardinality(String)"
    field :visitor_id, Ch, type: "UInt64"
    field :session_id, Ch, type: "String"
    field :name, Ch, type: "LowCardinality(String)"
    field :hostname, Ch, type: "LowCardinality(String)"
    field :pathname, Ch, type: "String"
    field :referrer, Ch, type: "String"
    field :referrer_source, Ch, type: "LowCardinality(String)"
    field :country_code, Ch, type: "LowCardinality(String)"
    field :browser_language, Ch, type: "LowCardinality(String)"
    field :served_locale, Ch, type: "LowCardinality(String)"
    field :has_locale_gap, Ch, type: "UInt8"
    field :device, Ch, type: "LowCardinality(String)"
    field :browser, Ch, type: "LowCardinality(String)"
    field :os, Ch, type: "LowCardinality(String)"
    field :screen_width, Ch, type: "UInt16"
    field :timezone, Ch, type: "LowCardinality(String)"
  end
end
