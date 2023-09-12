defmodule Glossia.Foundation.Database.Core.Repo.Migrations.RemoveTypeFromProject do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      remove :type
    end
  end
end
