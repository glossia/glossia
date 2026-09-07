defmodule Glossia.Repo.Migrations.AddHasAccessToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :has_access, :boolean, default: false, null: false
    end
  end
end
