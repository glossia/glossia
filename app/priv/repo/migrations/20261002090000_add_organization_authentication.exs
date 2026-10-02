defmodule Glossia.Repo.Migrations.AddOrganizationAuthentication do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :auth_provider, :string
      add :auth_domain, :string
      add :auth_domain_token, :string
      add :auth_domain_verified_at, :utc_datetime_usec
      add :auth_issuer, :string
      add :auth_client_id, :string
      add :auth_client_secret, :binary
    end

    create unique_index(:organizations, [:auth_domain],
             where: "auth_domain_verified_at IS NOT NULL"
           )

    create table(:organization_auth_blocks, primary_key: false) do
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        primary_key: true

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), primary_key: true
    end

    alter table(:organization_memberships) do
      # Null preserves existing role permissions; new members receive explicit scopes.
      add :scopes, {:array, :string}
    end
  end
end
