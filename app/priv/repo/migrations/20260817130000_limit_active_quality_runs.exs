defmodule Glossia.Repo.Migrations.LimitActiveQualityRuns do
  use Ecto.Migration

  def change do
    create unique_index(:quality_runs, [:project_id],
             name: :quality_runs_one_active_per_project_index,
             where: "status IN ('pending', 'running')"
           )
  end
end
