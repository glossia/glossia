defmodule Glossia.Repo.Migrations.CreateTranslationSessions do
  use Ecto.Migration

  def change do
    create table(:translation_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :commit_sha, :string
      add :commit_message, :string
      add :status, :string, null: false, default: "pending"
      add :source_language, :string
      add :target_languages, {:array, :string}, default: []
      add :summary, :string
      add :error, :text
      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:translation_sessions, [:project_id])
    create index(:translation_sessions, [:project_id, :commit_sha])
    create index(:translation_sessions, [:account_id])
  end
end
