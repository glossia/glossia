defmodule Glossia.Repo.Migrations.CreateQualitySessionEvents do
  use Ecto.Migration

  def change do
    create table(:quality_session_events, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :run_id, references(:quality_runs, type: :binary_id, on_delete: :delete_all),
        null: false

      add :page_id, references(:quality_pages, type: :binary_id, on_delete: :nilify_all)

      add :finding_id,
          references(:quality_findings, type: :binary_id, on_delete: :nilify_all)

      add :kind, :string, null: false
      add :label, :string, null: false
      add :detail, :text
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:quality_session_events, [:run_id, :inserted_at])
    create index(:quality_session_events, [:page_id])
    create index(:quality_session_events, [:finding_id])
  end
end
