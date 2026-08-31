defmodule Babel.Repo.Migrations.PromoteGoToMarketAccountsToOrganizations do
  use Ecto.Migration

  def change do
    rename table(:go_to_market_accounts), to: table(:organizations)
    rename table(:go_to_market_interactions), to: table(:organization_interactions)

    rename table(:go_to_market_prospects), :account_id, to: :organization_id
    rename table(:organization_interactions), :account_id, to: :organization_id
  end
end
