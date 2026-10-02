defmodule Glossia.Repo.Migrations.AddModelCategories do
  use Ecto.Migration

  def up do
    alter table(:llm_models) do
      add :category, :string, null: false, default: "generative"
      add :decision_min_score, :float, null: false, default: 7.0
    end

    drop index(:llm_models, [:account_id], name: :llm_models_one_default_per_account)

    create unique_index(:llm_models, [:account_id, :category],
             where: "\"default\"",
             name: :llm_models_one_default_per_category
           )

    create constraint(:llm_models, :llm_models_valid_category,
             check: "category IN ('generative', 'decision')"
           )

    create constraint(:llm_models, :llm_models_valid_decision_score,
             check: "decision_min_score >= 1 AND decision_min_score <= 10"
           )
  end

  def down do
    execute("DELETE FROM llm_models WHERE category = 'decision'")
    drop constraint(:llm_models, :llm_models_valid_category)
    drop constraint(:llm_models, :llm_models_valid_decision_score)
    drop index(:llm_models, [:account_id, :category], name: :llm_models_one_default_per_category)

    alter table(:llm_models) do
      remove :category
      remove :decision_min_score
    end

    create unique_index(:llm_models, [:account_id],
             where: "\"default\"",
             name: :llm_models_one_default_per_account
           )
  end
end
