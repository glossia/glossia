defmodule Glossia.Repo.Migrations.AddHasAccessToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add_if_not_exists :has_access, :boolean, default: false, null: false
    end
  end
end
