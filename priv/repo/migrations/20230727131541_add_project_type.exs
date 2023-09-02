defmodule Glossia.Foundation.Database.Core.Repo.Migrations.AddProjectType do
  use Ecto.Migration

  def change do
    alter table("projects") do
      add :type, :integer, null: true, default: 1
    end
  end
end
