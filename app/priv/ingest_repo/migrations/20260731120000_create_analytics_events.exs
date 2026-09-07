defmodule Glossia.IngestRepo.Migrations.CreateAnalyticsEvents do
  use Ecto.Migration

  @moduledoc """
  Website analytics events collected by the `@glossia/web` SDK.

  `inserted_at` is populated by the table default and is intentionally not part
  of the RowBinary payload written by `Glossia.Analytics.Ingestion`. The sort key
  optimizes the dashboard's dominant query shape: per project, per day, filtered
  and grouped by the localization-gap flag, country, and browser language.
  """

  def change do
    create table(:analytics_events,
             primary_key: false,
             engine: "MergeTree",
             options:
               "PARTITION BY toYYYYMM(inserted_at) ORDER BY (project_id, toDate(inserted_at), has_locale_gap, country_code, browser_language)"
           ) do
      add :id, :uuid, null: false
      add :project_id, :"LowCardinality(String)", null: false
      add :visitor_id, :UInt64, null: false
      add :session_id, :string, null: false
      add :name, :"LowCardinality(String)", null: false
      add :hostname, :"LowCardinality(String)", null: false
      add :pathname, :string, null: false
      add :referrer, :string, null: false
      add :referrer_source, :"LowCardinality(String)", null: false
      add :country_code, :"LowCardinality(String)", null: false
      add :browser_language, :"LowCardinality(String)", null: false
      add :served_locale, :"LowCardinality(String)", null: false
      add :has_locale_gap, :UInt8, null: false
      add :device, :"LowCardinality(String)", null: false
      add :browser, :"LowCardinality(String)", null: false
      add :os, :"LowCardinality(String)", null: false
      add :screen_width, :UInt16, null: false
      add :timezone, :"LowCardinality(String)", null: false
      add :inserted_at, :utc_datetime, default: fragment("now()")
    end
  end
end
