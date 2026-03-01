defmodule Glossia.Repo.Migrations.CreateOauthDeviceAuthorizations do
  use Ecto.Migration

  def change do
    create table(:oauth_device_authorizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_code_hash, :string, null: false
      add :user_code, :string, null: false
      add :scope, :string, null: false, default: ""
      add :status, :string, null: false, default: "pending"
      add :interval, :integer, null: false, default: 5
      add :expires_at, :utc_datetime_usec, null: false
      add :authorized_at, :utc_datetime_usec
      add :denied_at, :utc_datetime_usec
      add :consumed_at, :utc_datetime_usec
      add :last_polled_at, :utc_datetime_usec

      add :client_id, references(:oauth_clients, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:oauth_device_authorizations, [:device_code_hash])
    create unique_index(:oauth_device_authorizations, [:user_code])
    create index(:oauth_device_authorizations, [:status])
    create index(:oauth_device_authorizations, [:expires_at])
    create index(:oauth_device_authorizations, [:client_id])
  end
end
