defmodule Glossia.Repo.Migrations.DropRolesFromOrganizationInvitations do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE organization_invitations DROP COLUMN IF EXISTS role")
  end

  def down do
    execute(
      "ALTER TABLE organization_invitations ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'member'"
    )
  end
end
