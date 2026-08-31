defmodule Babel.Repo.Migrations.AddGlossiaOrganizationToGoToMarketAccounts do
  use Ecto.Migration

  def change do
    alter table(:go_to_market_accounts) do
      add :glossia_organization_id, :binary_id
    end

    create index(:go_to_market_accounts, [:glossia_organization_id])
  end
end
