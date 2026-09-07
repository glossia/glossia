defmodule Glossia.Repo.Migrations.CreateAccountTokens do
  use Ecto.Migration

  def change do
    create table(:account_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string
      add :token_hash, :string, null: false
      add :token_prefix, :string, null: false
      add :scope, :string, null: false, default: ""
      add :expires_at, :utc_datetime_usec
      add :last_used_at, :utc_datetime_usec
      add :revoked_at, :utc_datetime_usec

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:account_tokens, [:account_id])
    create index(:account_tokens, [:user_id])
    create unique_index(:account_tokens, [:token_hash])
  end
end
