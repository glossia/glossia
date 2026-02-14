defmodule Glossia.IngestRepo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events,
             primary_key: false,
             engine: "MergeTree",
             options: "ORDER BY (inserted_at, id)"
           ) do
      add :id, :uuid, null: false
      add :name, :string, null: false
      add :account_id, :string, null: false
      add :user_id, :string
      add :duration_ms, :UInt64
      add :metadata, :string
      add :inserted_at, :utc_datetime, default: fragment("now()")
    end
  end
end
