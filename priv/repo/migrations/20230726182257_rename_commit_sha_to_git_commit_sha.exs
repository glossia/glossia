defmodule Glossia.Repo.Migrations.RenameCommitShaToGitCommitSha do
  use Ecto.Migration

  def change do
    drop unique_index(:builds, [:commit_sha, :repository_id, :vcs])

    rename table("builds"), :commit_sha, to: :git_commit_sha
    rename table("builds"), :vcs, to: :git_vcs
    rename table("builds"), :repository_id, to: :git_repository_id

    rename table("projects"), :repository_id, to: :git_repository_id
    rename table("projects"), :vcs, to: :git_vcs

    create unique_index(:builds, [:git_commit_sha, :git_repository_id, :git_vcs])
  end
end
