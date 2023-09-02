defmodule Glossia.Foundation.Database.Core.Repo.Migrations.AddVisibilityToProjects do
  use Ecto.Migration

  def change do
    alter table("projects") do
      add :visibility, :integer, null: false, default: 1
    end
  end
end
