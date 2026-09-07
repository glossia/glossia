defmodule Glossia.Repo.Migrations.CreateTemporaryAccessGrants do
  use Ecto.Migration

  def change do
    create table(:temporary_access_grants, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :recipient_user_id, references(:users, type: :binary_id, on_delete: :delete_all),
        null: false

      add :recipient_email, :string, null: false
      add :requested_by_email, :string, null: false
      add :requested_by_pomerium_id, :string, null: false
      add :pomerium_subject, :string
      add :reason, :text, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :revoked_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:temporary_access_grants, [:account_id, :recipient_user_id, :expires_at])
    create index(:temporary_access_grants, [:recipient_user_id, :pomerium_subject])
  end
end
