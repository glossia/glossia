defmodule GlossiaEnterprise.Identity.Migration do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:organization_security_settings, primary_key: false) do
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        primary_key: true

      add :sso_enforced, :boolean, default: false, null: false
    end

    create table(:scim_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false

      add :name, :text, null: false
      add :token_hash, :binary, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:scim_tokens, [:token_hash])
    create index(:scim_tokens, [:organization_id])

    create table(:scim_users, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :external_id, :text
      add :display_name, :text
      add :active, :boolean, default: true, null: false
      add :identity_linkable, :boolean, default: false, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:scim_users, [:organization_id, :user_id])
    create unique_index(:scim_users, [:organization_id, :external_id])
  end
end
