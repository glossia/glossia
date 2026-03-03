defmodule Glossia.Repo.Migrations.AddContentSourceToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :content_source, :string, default: "github", null: false
      add :content_source_path, :string
    end
  end
end
