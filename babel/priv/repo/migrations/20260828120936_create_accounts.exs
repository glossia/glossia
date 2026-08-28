defmodule Babel.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :email, :string, null: false
      add :name, :string
      add :pomerium_id, :string, null: false
      add :last_seen_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts, [:email])
    create unique_index(:accounts, [:pomerium_id])
  end
end
