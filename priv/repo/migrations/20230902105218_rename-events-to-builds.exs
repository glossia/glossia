defmodule :"Elixir.Glossia.Repo.Migrations.Rename-events-to-builds" do
  use Ecto.Migration

  def change do
    drop unique_index(
           :events,
           [
             :version,
             :event,
             :content_source_id,
             :content_source_platform
           ],
           name: "events_version_type_content_source_id_content_source_platform_i"
         )

    rename table(:events), to: table(:builds)

    create unique_index(:builds, [
             :version,
             :type,
             :content_source_id,
             :content_source_platform
           ])
  end
end
