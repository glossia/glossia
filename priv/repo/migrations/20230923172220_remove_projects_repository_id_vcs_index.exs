defmodule Glossia.Repo.Migrations.RemoveProjectsRepositoryIdVcsIndex do
  use Ecto.Migration

  def change do
    drop index(:projects, [:repository_id, :vcs])
  end
end
