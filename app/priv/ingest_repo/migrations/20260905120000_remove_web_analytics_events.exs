defmodule Glossia.IngestRepo.Migrations.RemoveWebAnalyticsEvents do
  use Ecto.Migration

  def up do
    execute("DROP TABLE IF EXISTS analytics_events")
  end

  def down, do: :ok
end
