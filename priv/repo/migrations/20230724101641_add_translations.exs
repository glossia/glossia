defmodule Glossia.Foundation.Database.Core.Repo.Migrations.AddTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :commit_sha, :string, null: false
      add :repository_id, :citext, null: false
      add :vcs, :integer, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:translations, [:commit_sha, :repository_id, :vcs])
  end
end
