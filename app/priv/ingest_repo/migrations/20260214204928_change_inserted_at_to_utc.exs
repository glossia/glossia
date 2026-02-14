defmodule Glossia.IngestRepo.Migrations.ChangeInsertedAtToUtc do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE events MODIFY COLUMN inserted_at DateTime('UTC') DEFAULT now()")
  end

  def down do
    execute("ALTER TABLE events MODIFY COLUMN inserted_at DateTime DEFAULT now()")
  end
end
