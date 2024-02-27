defmodule Glossia.Repo.Migrations.RenameContentSourceIdToContentId do
  use Ecto.Migration

  def change do
    drop unique_index(:projects, [:content_source_id, :content_source_platform])
    drop unique_index(:builds, [:version, :type, :content_source_id, :content_source_platform])

    rename table(:projects), :content_source_id, to: :id_in_content_platform
    rename table(:projects), :content_source_platform, to: :content_platform

    alter table(:builds) do
      remove :content_source_id
      remove :content_source_platform
    end

    create unique_index(:builds, [:version, :type])
    create unique_index(:projects, [:id_in_content_platform, :content_platform])
  end
end
