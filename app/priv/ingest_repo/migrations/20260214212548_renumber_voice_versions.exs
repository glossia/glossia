defmodule Glossia.IngestRepo.Migrations.RenumberVoiceVersions do
  use Ecto.Migration

  def change do
    # No-op: voice data lives in the main Postgres repo
  end
end
