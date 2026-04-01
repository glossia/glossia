defmodule Glossia.Repo.Migrations.CreateLlmModels do
  use Ecto.Migration

  def change do
    create table(:llm_models, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :handle, :string, null: false
      add :provider, :string, null: false
      add :model_id, :string, null: false
      add :api_key_encrypted, :binary, null: false

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:llm_models, [:account_id, :handle])
    create index(:llm_models, [:account_id])
  end
end
