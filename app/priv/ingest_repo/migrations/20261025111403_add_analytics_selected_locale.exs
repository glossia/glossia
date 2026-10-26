defmodule Glossia.IngestRepo.Migrations.AddAnalyticsSelectedLocale do
  use Ecto.Migration

  def change do
    alter table(:analytics_events) do
      add :selected_locale, :"LowCardinality(String)", default: ""
    end
  end
end
