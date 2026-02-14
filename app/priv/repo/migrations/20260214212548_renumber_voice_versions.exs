defmodule Glossia.Repo.Migrations.RenumberVoiceVersions do
  use Ecto.Migration

  def up do
    # Renumber voice versions per account so they are sequential (1, 2, 3, ...)
    # ordered by inserted_at (creation time).
    execute("""
    WITH ranked AS (
      SELECT id, ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY inserted_at) AS new_version
      FROM voices
    )
    UPDATE voices
    SET version = ranked.new_version
    FROM ranked
    WHERE voices.id = ranked.id
    """)
  end

  def down do
    # Not reversible -- the original Unix-timestamp versions are lost
    :ok
  end
end
