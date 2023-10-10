defmodule Glossia.Repo.Migrations.AddUniqueIndexToBuilds do
  use Ecto.Migration

  def change do
    create unique_index(:builds, [:git_commit_sha, :event, :vcs_id, :vcs_platform])
  end
end
