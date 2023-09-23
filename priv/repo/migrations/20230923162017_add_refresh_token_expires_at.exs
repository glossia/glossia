defmodule Glossia.Foundation.Database.Core.Repo.Migrations.AddRefreshTokenExpiresAt do
  use Ecto.Migration

  def change do
    alter table(:credentials) do
      add :refresh_token_expires_at, :utc_datetime, null: true
    end
  end
end
