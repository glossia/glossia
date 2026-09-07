defmodule Glossia.IngestRepo.Migrations.CreateSetupEvents do
  use Ecto.Migration

  def change do
    create table(:setup_events,
             primary_key: false,
             engine: "MergeTree",
             options: "ORDER BY (project_id, sequence)"
           ) do
      add :id, :uuid, null: false
      add :project_id, :string, null: false
      add :sequence, :UInt32, null: false
      add :event_type, :"LowCardinality(String)", null: false
      add :content, :string
      add :metadata, :string
      add :inserted_at, :utc_datetime, default: fragment("now()")
    end
  end
end
