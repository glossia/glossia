defmodule Babel.Repo.Migrations.CreateGoToMarketAccountsAndInteractions do
  use Ecto.Migration

  def change do
    create table(:go_to_market_accounts) do
      add :name, :string, null: false
      add :website_url, :string, null: false
      add :state, :string, null: false, default: "researching"
      add :owner, :string, null: false, default: "Unassigned"
      add :translation_tool, :string
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:go_to_market_accounts, [:name])
    create unique_index(:go_to_market_accounts, [:website_url])
    create index(:go_to_market_accounts, [:state])

    alter table(:go_to_market_prospects) do
      add :account_id, references(:go_to_market_accounts, on_delete: :nilify_all)
    end

    create index(:go_to_market_prospects, [:account_id])

    create table(:go_to_market_interactions) do
      add :account_id, references(:go_to_market_accounts, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :summary, :string, null: false
      add :body, :text
      add :source_url, :string
      add :occurred_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:go_to_market_interactions, [:account_id, :occurred_at])
  end
end
