defmodule Glossia.Repo.Migrations.AddStripeCustomerIdToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :customer_id, :string, null: true
    end

    create unique_index(:accounts, [:customer_id])
  end
end
