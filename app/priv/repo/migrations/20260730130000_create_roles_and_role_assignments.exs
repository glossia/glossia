defmodule Glossia.Repo.Migrations.CreateRolesAndRoleAssignments do
  use Ecto.Migration

  def up do
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :scope, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:roles, [:scope, :name])

    create table(:role_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :role_id, references(:roles, type: :binary_id, on_delete: :delete_all), null: false

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:role_assignments, [:user_id, :role_id, :organization_id])
    create index(:role_assignments, [:organization_id])

    execute """
    INSERT INTO roles (id, name, scope, inserted_at, updated_at)
    VALUES
      (gen_random_uuid(), 'super_admin', 'instance', NOW(), NOW()),
      (gen_random_uuid(), 'admin', 'organization', NOW(), NOW()),
      (gen_random_uuid(), 'member', 'organization', NOW(), NOW()),
      (gen_random_uuid(), 'linguist', 'organization', NOW(), NOW())
    """

    execute """
    INSERT INTO role_assignments (id, user_id, role_id, organization_id, inserted_at, updated_at)
    SELECT gen_random_uuid(), memberships.user_id, roles.id, memberships.organization_id,
           memberships.inserted_at, memberships.updated_at
    FROM organization_memberships AS memberships
    INNER JOIN roles ON roles.scope = 'organization' AND roles.name = memberships.role
    """

    execute """
    INSERT INTO role_assignments (id, user_id, role_id, inserted_at, updated_at)
    SELECT gen_random_uuid(), users.id, roles.id, users.inserted_at, users.updated_at
    FROM users
    INNER JOIN roles ON roles.scope = 'instance' AND roles.name = 'super_admin'
    WHERE users.super_admin = TRUE
    """
  end

  def down do
    drop table(:role_assignments)
    drop table(:roles)
  end
end
