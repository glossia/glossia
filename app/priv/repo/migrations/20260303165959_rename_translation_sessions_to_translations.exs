defmodule Glossia.Repo.Migrations.RenameTranslationSessionsToTranslations do
  use Ecto.Migration

  def change do
    rename table(:translation_sessions), to: table(:translations)

    alter table(:translations) do
      add :sandbox_id, :string
    end

    create index(:translations, [:sandbox_id])
  end
end
