defmodule Glossia.Repo.Migrations.AddUniquenessToProjectsContentSourceIdAndPlatform do
  use Ecto.Migration

  def change do
    create unique_index(:projects, [:content_source_id, :content_source_platform])
  end
end
