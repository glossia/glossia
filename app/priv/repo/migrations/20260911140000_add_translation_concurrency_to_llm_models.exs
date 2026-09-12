defmodule Glossia.Repo.Migrations.AddTranslationConcurrencyToLlmModels do
  use Ecto.Migration

  def up do
    alter table(:llm_models) do
      add :translation_concurrency, :integer
    end

    create constraint(:llm_models, :translation_concurrency_positive,
             check: "translation_concurrency IS NULL OR translation_concurrency > 0"
           )

    # Every already-configured model runs uncapped today. Seed a conservative
    # per-model default so a repository that would previously fan out to the
    # full HTTP pool cannot silently regress into a wall of provider 429s the
    # moment this column becomes the sole source of truth. Operators dial it
    # up or down from the LLM model settings page as they learn what their
    # provider tolerates.
    execute("""
    UPDATE llm_models
    SET translation_concurrency = 5
    WHERE translation_concurrency IS NULL
    """)
  end

  def down do
    drop constraint(:llm_models, :translation_concurrency_positive)

    alter table(:llm_models) do
      remove :translation_concurrency
    end
  end
end
