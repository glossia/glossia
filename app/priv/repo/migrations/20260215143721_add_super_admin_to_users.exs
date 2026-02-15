defmodule Glossia.Repo.Migrations.AddSuperAdminToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :super_admin, :boolean, default: false, null: false
    end
  end
end
