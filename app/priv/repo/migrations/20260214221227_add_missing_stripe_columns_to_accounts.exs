defmodule Glossia.Repo.Migrations.AddMissingStripeColumnsToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add_if_not_exists :stripe_customer_id, :string
      add_if_not_exists :stripe_subscription_id, :string
      add_if_not_exists :stripe_subscription_status, :string
      add_if_not_exists :stripe_current_period_end, :utc_datetime_usec
    end

    create_if_not_exists unique_index(:accounts, [:stripe_customer_id])
    create_if_not_exists unique_index(:accounts, [:stripe_subscription_id])
  end
end
