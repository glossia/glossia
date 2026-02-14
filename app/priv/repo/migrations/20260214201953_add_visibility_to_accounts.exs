defmodule Glossia.Repo.Migrations.AddVisibilityToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :visibility, :string, null: false, default: "private"
    end
  end
end
