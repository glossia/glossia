defmodule Glossia.Repo.Migrations.AddStripeBillingToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :has_access, :boolean, default: false, null: false
      add :stripe_customer_id, :string
      add :stripe_subscription_id, :string
      add :stripe_subscription_status, :string
      add :stripe_current_period_end, :utc_datetime_usec
    end

    create unique_index(:accounts, [:stripe_customer_id])
    create unique_index(:accounts, [:stripe_subscription_id])

    execute(
      """
      UPDATE accounts
      SET has_access = users.has_access
      FROM users
      WHERE users.account_id = accounts.id
      """,
      "SELECT 1"
    )
  end
end
