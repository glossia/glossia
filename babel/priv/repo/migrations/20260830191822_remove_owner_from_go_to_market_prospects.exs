defmodule Babel.Repo.Migrations.RemoveOwnerFromGoToMarketProspects do
  use Ecto.Migration

  def change do
    alter table(:go_to_market_prospects) do
      remove :owner
    end
  end
end
