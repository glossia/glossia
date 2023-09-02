defmodule Glossia.Foundation.Database.Core.Repo.Migrations.MakeProjectsVcsAndRepositoryIdUnique do
  use Ecto.Migration

  def change do
    create unique_index(:projects, [:repository_id, :vcs])
  end
end
