defmodule Glossia.IngestRepo.Migrations.CreateTranslationSessionEvents do
  use Ecto.Migration

  def change do
    create table(:translation_session_events,
             primary_key: false,
             engine: "MergeTree",
             options: "ORDER BY (session_id, sequence)"
           ) do
      add :id, :uuid, null: false
      add :session_id, :string, null: false
      add :sequence, :UInt32, null: false
      add :event_type, :"LowCardinality(String)", null: false
      add :content, :string
      add :metadata, :string
      add :inserted_at, :utc_datetime, default: fragment("now()")
    end
  end
end
