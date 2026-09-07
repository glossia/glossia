defmodule Glossia.Repo.Migrations.RemoveAccessFlags do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :has_access
    end

    alter table(:accounts) do
      remove :has_access
    end
  end

  def down do
    alter table(:users) do
      add :has_access, :boolean, default: true, null: false
    end

    alter table(:accounts) do
      add :has_access, :boolean, default: true, null: false
    end
  end
end
