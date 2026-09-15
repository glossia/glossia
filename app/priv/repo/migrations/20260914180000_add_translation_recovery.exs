defmodule Glossia.Repo.Migrations.AddTranslationRecovery do
  use Ecto.Migration

  def change do
    alter table(:translation_sessions) do
      add :provider_retry_count, :integer, null: false, default: 0
    end

    create table(:translation_segment_checkpoints, primary_key: false) do
      add :key, :text, primary_key: true
      add :result, :map, null: false
      add :expires_at, :utc_datetime_usec, null: false
    end

    create index(:translation_segment_checkpoints, [:expires_at])

    create table(:translation_provider_pacing, primary_key: false) do
      add :key, :text, primary_key: true
      add :next_at, :bigint, null: false, default: 0
      add :interval_ms, :integer, null: false, default: 0
      add :limited_at, :bigint, null: false, default: 0
      add :expires_at, :utc_datetime_usec, null: false
    end

    create index(:translation_provider_pacing, [:expires_at])
  end
end
