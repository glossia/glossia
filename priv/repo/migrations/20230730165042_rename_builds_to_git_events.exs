defmodule Glossia.Repo.Migrations.RenameBuildsToGitEvents do
  use Ecto.Migration

  def change do
    drop unique_index(:builds, [:git_commit_sha, :event, :vcs_id, :vcs_platform])
    rename table(:builds), to: table(:git_events)
  end
end
