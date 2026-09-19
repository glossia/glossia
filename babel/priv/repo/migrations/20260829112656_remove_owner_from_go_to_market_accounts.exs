defmodule Babel.Repo.Migrations.RemoveOwnerFromGoToMarketAccounts do
  use Ecto.Migration

  def change do
    alter table(:go_to_market_accounts) do
      remove :owner, :string
    end
  end
end
