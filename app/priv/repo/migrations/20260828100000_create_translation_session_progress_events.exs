defmodule Glossia.Repo.Migrations.CreateTranslationSessionProgressEvents do
  use Ecto.Migration

  def change do
    create table(:translation_session_progress_events, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :session_id,
          references(:translation_sessions, type: :binary_id, on_delete: :delete_all),
          null: false

      add :seq, :integer, null: false
      add :payload, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    # Folding a session's panel reads every row in `seq` order, and the
    # uniqueness makes a re-delivered event a no-op rather than a duplicate.
    create unique_index(:translation_session_progress_events, [:session_id, :seq])
  end
end
