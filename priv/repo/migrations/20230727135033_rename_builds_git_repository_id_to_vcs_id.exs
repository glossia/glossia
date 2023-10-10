defmodule Glossia.Repo.Migrations.RenameBuildsGitRepositoryIdToVcsId do
  use Ecto.Migration

  def change do
    rename table("builds"), :git_repository_id, to: :vcs_id
  end
end
