defmodule Glossia.Repo.Migrations.RemoveQuality do
  use Ecto.Migration

  def up do
    drop_if_exists table(:quality_session_events)
    drop_if_exists table(:project_context_entries)
    drop_if_exists table(:quality_occurrences)
    drop_if_exists table(:quality_pages)
    drop_if_exists table(:quality_findings)
    drop_if_exists table(:project_context_versions)
    drop_if_exists table(:quality_runs)
    drop_if_exists table(:quality_profiles)
  end

  def down, do: :ok
end
