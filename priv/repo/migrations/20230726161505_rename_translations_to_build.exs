defmodule Glossia.Repo.Migrations.RenameTranslationsToBuild do
  use Ecto.Migration

  def change do
    drop table(:translations)

    create table(:builds) do
      add :commit_sha, :string, null: false
      add :event, :integer, null: false
      add :repository_id, :citext, null: false
      add :vcs, :integer, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :status, :integer, default: 1, null: false
      add :remote_id, :string, null: true
      timestamps()
    end

    create index(:builds, [:remote_id])
    create index(:builds, [:status])
    create unique_index(:builds, [:commit_sha, :repository_id, :vcs])
  end
end
