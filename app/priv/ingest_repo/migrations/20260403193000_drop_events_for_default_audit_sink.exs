defmodule Glossia.IngestRepo.Migrations.DropEventsForDefaultAuditSink do
  use Ecto.Migration

  def up do
    if Application.get_env(:glossia, :event_handler, Glossia.Events.NoopHandler) ==
         Glossia.Events.NoopHandler do
      execute("DROP TABLE IF EXISTS events")
    end
  end

  def down do
    :ok
  end
end
