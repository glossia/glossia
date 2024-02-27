defmodule Glossia.Repo.Migrations.RenameProjectsToContentSources do
  use Ecto.Migration

  def change do
    drop unique_index(:projects, [:handle, :account_id])
    drop unique_index(:projects, [:id_in_platform, :platform])

    alter table(:builds) do
      remove :project_id
    end

    alter table(:users) do
      remove :last_visited_project_id
    end

    alter table(:projects) do
      remove :handle
      remove :visibility
    end

    rename table(:projects), to: table(:content_sources)

    create unique_index(:content_sources, [:id_in_platform, :platform])
  end
end
