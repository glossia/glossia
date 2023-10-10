defmodule Glossia.Repo.Migrations.RenameBuildsGitVcsToVcsPlatform do
  use Ecto.Migration

  def change do
    drop unique_index(:builds, [:git_commit_sha, :git_repository_id, :git_vcs])
    rename table("builds"), :git_vcs, to: :vcs_platform
  end
end
