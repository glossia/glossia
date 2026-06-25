defmodule Glossia.Repo.Migrations.BackfillPersonalOrganizations do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto"

    execute """
    INSERT INTO organizations (id, account_id, name, inserted_at, updated_at)
    SELECT gen_random_uuid(), accounts.id, 'Personal', now(), now()
    FROM accounts
    INNER JOIN users ON users.account_id = accounts.id
    LEFT JOIN organizations ON organizations.account_id = accounts.id
    WHERE accounts.type = 'user' AND organizations.id IS NULL
    """

    execute """
    INSERT INTO organization_memberships (id, user_id, organization_id, role, inserted_at, updated_at)
    SELECT gen_random_uuid(), users.id, organizations.id, 'admin', now(), now()
    FROM users
    INNER JOIN accounts ON accounts.id = users.account_id
    INNER JOIN organizations ON organizations.account_id = accounts.id
    LEFT JOIN organization_memberships
      ON organization_memberships.user_id = users.id
      AND organization_memberships.organization_id = organizations.id
    WHERE accounts.type = 'user' AND organization_memberships.id IS NULL
    """
  end

  def down do
    execute """
    DELETE FROM organization_memberships
    USING users, accounts, organizations
    WHERE organization_memberships.user_id = users.id
      AND organization_memberships.organization_id = organizations.id
      AND users.account_id = accounts.id
      AND organizations.account_id = accounts.id
      AND accounts.type = 'user'
      AND organizations.name = 'Personal'
    """

    execute """
    DELETE FROM organizations
    USING users, accounts
    WHERE organizations.account_id = accounts.id
      AND users.account_id = accounts.id
      AND accounts.type = 'user'
      AND organizations.name = 'Personal'
    """
  end
end
