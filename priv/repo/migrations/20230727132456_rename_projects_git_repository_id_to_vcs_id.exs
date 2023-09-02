defmodule Glossia.Foundation.Database.Core.Repo.Migrations.RenameProjectsGitRepositoryIdToVcsId do
  use Ecto.Migration

  def change do
    rename table("projects"), :git_repository_id, to: :vcs_id
  end
end
