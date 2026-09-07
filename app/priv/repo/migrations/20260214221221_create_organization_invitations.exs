defmodule Glossia.Repo.Migrations.CreateOrganizationInvitations do
  use Ecto.Migration

  def change do
    create table(:organization_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :role, :string, null: false, default: "member"
      add :token, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :expires_at, :utc_datetime_usec, null: false

      add :organization_id,
          references(:organizations, type: :binary_id, on_delete: :delete_all),
          null: false

      add :invited_by_id,
          references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:organization_invitations, [:token])
    create index(:organization_invitations, [:organization_id])
  end
end
