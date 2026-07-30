defmodule Glossia.Repo.Migrations.CreateAnalyticsProjectSettings do
  use Ecto.Migration

  def change do
    create table(:analytics_project_settings) do
      add :public_key, :string, null: false
      add :enabled, :boolean, null: false, default: true

      add :project_id, references(:projects, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:analytics_project_settings, [:public_key])
    create unique_index(:analytics_project_settings, [:project_id])
  end
end
