defmodule Glossia.Repo.Migrations.AddTranslationEngineProvenance do
  use Ecto.Migration

  def change do
    alter table(:translation_sessions) do
      add :engine_image, :text
      add :engine_retry_count, :integer, null: false, default: 0
      add :previous_engine_images, {:array, :text}, null: false, default: []
      add :failure_kind, :text
    end

    create index(:translation_sessions, [:completed_at, :id],
             name: :translation_sessions_engine_recovery_index,
             where:
               "status = 'failed' AND failure_kind = 'translation_items_failed' AND engine_image IS NOT NULL AND engine_retry_count < 3"
           )
  end
end
