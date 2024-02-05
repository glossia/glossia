defmodule Glossia.Repo.Migrations.AddLastVisitedProjectIdToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_visited_project_id, references(:projects, on_delete: :nilify_all), null: true
    end
  end
end
