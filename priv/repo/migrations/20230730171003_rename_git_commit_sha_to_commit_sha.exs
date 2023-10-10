defmodule Glossia.Repo.Migrations.RenameGitCommitShaToCommitSha do
  use Ecto.Migration

  def change do
    drop table(:git_events)

    create table(:git_events) do
      add :commit_sha, :string, null: false
      add :event, :integer, null: false
      add :vcs_id, :citext, null: false
      add :vcs_platform, :integer, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :status, :integer, default: 1, null: false
      add :vm_id, :string, null: true
      timestamps()
    end

    create unique_index(:git_events, [:commit_sha, :event, :vcs_id, :vcs_platform])
  end
end
