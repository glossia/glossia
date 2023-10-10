defmodule Glossia.Repo.Migrations.AddProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :handle, :citext, null: false
      add :account_id, references(:accounts), null: false
      add :repository_id, :citext, null: false
      add :vcs, :integer, null: false
      timestamps()
    end

    create unique_index(:projects, [:account_id, :handle])
  end
end
