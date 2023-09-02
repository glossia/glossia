defmodule Glossia.Foundation.Database.Core.Repo.Migrations.RenameOrganizationUsersTable do
  use Ecto.Migration

  def change do
    drop table(:organization_users)

    create table(:organization_users) do
      add :role, :integer, null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:organization_users, [:organization_id, :user_id])
  end
end
