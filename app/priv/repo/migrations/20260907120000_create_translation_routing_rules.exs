defmodule Glossia.Repo.Migrations.CreateTranslationRoutingRules do
  use Ecto.Migration

  def change do
    create table(:translation_routing_rules, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false

      add :llm_model_id, references(:llm_models, type: :uuid, on_delete: :delete_all),
        null: false

      add :position, :integer, null: false
      add :target_locale, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:translation_routing_rules, [:account_id])
    create index(:translation_routing_rules, [:llm_model_id])

    create unique_index(:translation_routing_rules, [:account_id, :position],
             name: :translation_routing_rules_account_position_index
           )
  end
end
