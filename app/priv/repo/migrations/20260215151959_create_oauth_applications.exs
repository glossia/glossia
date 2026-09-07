defmodule Glossia.Repo.Migrations.CreateOauthApplications do
  use Ecto.Migration

  def change do
    create table(:oauth_applications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string
      add :homepage_url, :string

      add :boruta_client_id, references(:oauth_clients, type: :binary_id, on_delete: :delete_all),
        null: false

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:oauth_applications, [:account_id])
    create unique_index(:oauth_applications, [:boruta_client_id])
  end
end
