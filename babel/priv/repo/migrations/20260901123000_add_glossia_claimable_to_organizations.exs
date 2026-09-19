defmodule Babel.Repo.Migrations.AddGlossiaClaimableToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :glossia_claimable, :boolean, default: false, null: false
    end
  end
end
