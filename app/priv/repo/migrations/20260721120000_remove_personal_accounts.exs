defmodule Glossia.Repo.Migrations.RemovePersonalAccounts do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto"

    execute """
    INSERT INTO organizations (id, account_id, name, inserted_at, updated_at)
    SELECT gen_random_uuid(), accounts.id, 'Personal', now(), now()
    FROM accounts
    INNER JOIN users ON users.account_id = accounts.id
    LEFT JOIN organizations ON organizations.account_id = accounts.id
    WHERE organizations.id IS NULL
    """

    execute """
    INSERT INTO organization_memberships (id, user_id, organization_id, role, inserted_at, updated_at)
    SELECT gen_random_uuid(), users.id, organizations.id, 'admin', now(), now()
    FROM users
    INNER JOIN organizations ON organizations.account_id = users.account_id
    LEFT JOIN organization_memberships
      ON organization_memberships.user_id = users.id
      AND organization_memberships.organization_id = organizations.id
    WHERE organization_memberships.id IS NULL
    """

    execute """
    UPDATE organization_memberships
    SET role = 'admin', updated_at = now()
    FROM users, organizations
    WHERE users.account_id = organizations.account_id
      AND organization_memberships.user_id = users.id
      AND organization_memberships.organization_id = organizations.id
      AND organization_memberships.role != 'admin'
    """

    alter table(:accounts) do
      remove :type
    end
  end

  def down do
    alter table(:accounts) do
      add :type, :string, null: false, default: "organization"
    end

    execute """
    UPDATE accounts
    SET type = 'user'
    FROM users
    WHERE users.account_id = accounts.id
    """

    alter table(:accounts) do
      modify :type, :string, null: false, default: "user"
    end
  end
end
