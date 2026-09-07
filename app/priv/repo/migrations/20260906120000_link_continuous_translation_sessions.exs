defmodule Glossia.Repo.Migrations.LinkContinuousTranslationSessions do
  use Ecto.Migration

  def change do
    alter table(:translation_sessions) do
      add :continued_from_session_id,
          references(:translation_sessions, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:translation_sessions, [:continued_from_session_id])
  end
end
