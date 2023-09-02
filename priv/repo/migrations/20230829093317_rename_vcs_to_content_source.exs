defmodule Glossia.Foundation.Database.Core.Repo.Migrations.RenameVcsToContentSource do
  use Ecto.Migration

  def change do
    drop unique_index(:git_events, [:commit_sha, :event, :vcs_id, :vcs_platform])

    rename table(:projects), :vcs_id, to: :content_source_id
    rename table(:projects), :vcs_platform, to: :content_source_platform
    rename table(:git_events), :vcs_id, to: :content_source_id
    rename table(:git_events), :vcs_platform, to: :content_source_platform

    create unique_index(:git_events, [
             :commit_sha,
             :event,
             :content_source_id,
             :content_source_platform
           ])
  end
end
