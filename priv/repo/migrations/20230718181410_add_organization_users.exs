defmodule Glossia.Repo.Migrations.AddOrganizationUsers do
  use Ecto.Migration

  def change do
    create table(:organization_users) do
      add :role, :integer, null: false
      add :organization_id, references(:organizations), null: false
      add :user_id, references(:users), null: false
      timestamps()
    end

    create unique_index(:organization_users, [:organization_id, :user_id])
  end
end
