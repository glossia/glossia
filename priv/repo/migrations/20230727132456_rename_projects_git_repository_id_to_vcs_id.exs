defmodule Glossia.Repo.Migrations.RenameProjectsGitRepositoryIdToVcsId do
  use Ecto.Migration

  def change do
    rename table("projects"), :git_repository_id, to: :vcs_id
  end
end
