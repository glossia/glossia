defmodule Glossia.Repo.Migrations.AddTypeToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :type, :string, null: false, default: "user"
    end
  end
end
