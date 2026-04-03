defmodule Glossia.Repo.Migrations.DropRolesFromOrganizationMemberships do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE organization_memberships DROP COLUMN IF EXISTS role")
  end

  def down do
    execute(
      "ALTER TABLE organization_memberships ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'member'"
    )
  end
end
