defmodule Glossia.Repo.Migrations.AddClaimableToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :claimable, :boolean, default: false, null: false
    end
  end
end
