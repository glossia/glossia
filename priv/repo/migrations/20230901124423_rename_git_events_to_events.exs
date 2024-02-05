defmodule Glossia.Repo.Migrations.RenameGitEventsToEvents do
  use Ecto.Migration

  def change do
    drop unique_index(
           :git_events,
           [
             :commit_sha,
             :event,
             :content_source_id,
             :content_source_platform
           ],
           name: "git_events_commit_sha_event_content_source_id_content_source_pl"
         )

    rename table(:git_events), :commit_sha, to: :version
    rename table(:git_events), :event, to: :type
    rename table(:git_events), to: table(:events)

    alter table(:events) do
      add :metadata, :map, default: %{}
    end

    create unique_index(:events, [
             :version,
             :type,
             :content_source_id,
             :content_source_platform
           ])
  end
end
