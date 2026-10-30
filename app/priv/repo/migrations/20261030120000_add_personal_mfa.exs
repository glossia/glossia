defmodule Glossia.Repo.Migrations.AddPersonalMFA do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Once a factor changes, pre-MFA cookies must never authenticate again.
      add :authentication_version, :integer, default: 0, null: false
    end

    create table(:user_factors, primary_key: false) do
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), primary_key: true
      add :secret, :binary, null: false
      add :confirmed_at, :utc_datetime_usec
      add :enrollment_token_hash, :binary, null: false
      add :enrollment_expires_at, :utc_datetime_usec, null: false
      add :last_used_step, :bigint
      add :recovery_hashes, {:array, :binary}, default: [], null: false
      add :failed_attempts, :integer, default: 0, null: false
      add :attempt_window_started_at, :utc_datetime_usec
    end

    create table(:browser_sessions, primary_key: false) do
      add :token_hash, :binary, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :context, :string, null: false
      add :authentication_version, :integer, null: false
      add :authenticated_at, :utc_datetime_usec, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :mfa_verified_at, :utc_datetime_usec
      add :organization_sso, :string
    end

    create index(:browser_sessions, [:user_id])
    create index(:browser_sessions, [:expires_at])
  end
end
