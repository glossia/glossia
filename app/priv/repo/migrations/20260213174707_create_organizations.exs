defmodule Glossia.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:account_id])
  end
end
