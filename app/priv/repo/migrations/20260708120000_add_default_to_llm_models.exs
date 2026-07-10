defmodule Glossia.Repo.Migrations.AddDefaultToLlmModels do
  use Ecto.Migration

  def change do
    alter table(:llm_models) do
      add :default, :boolean, null: false, default: false
    end

    # At most one default model per account.
    create unique_index(:llm_models, [:account_id],
             where: "\"default\"",
             name: :llm_models_one_default_per_account
           )
  end
end
