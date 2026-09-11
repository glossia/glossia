defmodule Glossia.Repo.Migrations.AddTranslationConcurrencyToLlmModels do
  use Ecto.Migration

  def change do
    alter table(:llm_models) do
      add :translation_concurrency, :integer
    end

    create constraint(:llm_models, :translation_concurrency_positive,
             check: "translation_concurrency IS NULL OR translation_concurrency > 0"
           )
  end
end
