defmodule Glossia.IngestRepo.Migrations.DropEventsForDefaultAuditSink do
  use Ecto.Migration

  def up do
    if Application.get_env(:glossia, :audit_sink, Glossia.Auditing.DefaultSink) ==
         Glossia.Auditing.DefaultSink do
      execute("DROP TABLE IF EXISTS events")
    end
  end

  def down do
    :ok
  end
end
