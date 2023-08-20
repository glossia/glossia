defmodule Glossia.Repo.Migrations.AddAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :handle, :citext, null: false
      timestamps()
    end

    create unique_index(:accounts, [:handle])

    create table(:organizations) do
      add :account_id, references(:accounts), null: false
      timestamps()
    end

    create unique_index(:organizations, [:account_id])

    alter table(:users) do
      add :account_id, references(:accounts), null: false
    end

    create unique_index(:users, [:account_id])
  end
end
