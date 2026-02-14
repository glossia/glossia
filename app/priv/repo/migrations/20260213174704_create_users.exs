defmodule Glossia.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :email, :string, null: false
      add :name, :string
      add :avatar_url, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:account_id])
    create unique_index(:users, [:email])
  end
end
