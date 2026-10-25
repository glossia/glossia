defmodule Glossia.Repo.Migrations.CreatePushInstallations do
  use Ecto.Migration

  def change do
    create table(:push_installations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
      # Keep the client ID after OAuth client deletion, so the tombstone survives.
      add :oauth_client_id, :uuid, null: false
      add :platform, :text
      add :environment, :text
      add :token, :binary
      add :token_digest, :binary
      add :last_registered_at, :utc_datetime_usec
      add :retired_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create index(:push_installations, [:user_id, :last_registered_at])

    create unique_index(:push_installations, [:token_digest],
             where: "retired_at IS NULL",
             name: :push_installations_live_token_digest_index
           )

    create constraint(:push_installations, :push_installation_shape,
             check: """
             (retired_at IS NOT NULL AND user_id IS NULL AND token IS NULL AND token_digest IS NULL)
             OR (retired_at IS NULL AND token IS NOT NULL AND token_digest IS NOT NULL
                 AND last_registered_at IS NOT NULL AND
                 ((platform = 'ios' AND environment IN ('sandbox', 'production'))
                  OR (platform = 'android' AND environment = 'production')))
             """
           )
  end
end
