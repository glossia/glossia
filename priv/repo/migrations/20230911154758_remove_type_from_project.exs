defmodule Glossia.Repo.Migrations.RemoveTypeFromProject do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      remove :type
    end
  end
end
