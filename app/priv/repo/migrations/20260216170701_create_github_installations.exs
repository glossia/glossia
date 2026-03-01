defmodule Glossia.Repo.Migrations.CreateGithubInstallations do
  use Ecto.Migration

  def change do
    create table(:github_installations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :github_installation_id, :bigint, null: false
      add :github_account_login, :string, null: false
      add :github_account_type, :string, null: false
      add :github_account_id, :bigint, null: false
      add :suspended_at, :utc_datetime

      timestamps()
    end

    create unique_index(:github_installations, [:github_installation_id])
    create index(:github_installations, [:account_id])
  end
end
