defmodule Glossia.IngestRepo.Migrations.AddAuditColumnsToEvents do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE events ADD COLUMN IF NOT EXISTS actor_handle String AFTER user_id")
    execute("ALTER TABLE events ADD COLUMN IF NOT EXISTS actor_email String AFTER actor_handle")

    execute(
      "ALTER TABLE events ADD COLUMN IF NOT EXISTS resource_type LowCardinality(String) AFTER actor_email"
    )

    execute("ALTER TABLE events ADD COLUMN IF NOT EXISTS resource_id String AFTER resource_type")

    execute(
      "ALTER TABLE events ADD COLUMN IF NOT EXISTS resource_path String AFTER resource_id"
    )

    execute("ALTER TABLE events ADD COLUMN IF NOT EXISTS summary String AFTER resource_path")
  end

  def down do
    execute("ALTER TABLE events DROP COLUMN IF EXISTS actor_handle")
    execute("ALTER TABLE events DROP COLUMN IF EXISTS actor_email")
    execute("ALTER TABLE events DROP COLUMN IF EXISTS resource_type")
    execute("ALTER TABLE events DROP COLUMN IF EXISTS resource_id")
    execute("ALTER TABLE events DROP COLUMN IF EXISTS resource_path")
    execute("ALTER TABLE events DROP COLUMN IF EXISTS summary")
  end
end
