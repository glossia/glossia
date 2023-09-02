defmodule Glossia.Foundation.Database.Core.Repo.Migrations.AddUserCredentials do
  use Ecto.Migration

  def change do
    create table(:credentials) do
      add :user_id, references(:users), null: false
      add :provider, :integer, null: false
      add :provider_id, :integer, null: false
      add :token, :string, null: false
      add :refresh_token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      timestamps()
    end

    create unique_index(:credentials, [:user_id, :provider])
  end
end
