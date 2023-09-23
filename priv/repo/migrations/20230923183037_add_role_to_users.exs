defmodule Glossia.Foundation.Database.Core.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :integer, default: 0
    end
  end
end
