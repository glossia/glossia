defmodule Babel.Repo.Migrations.AddGlossiaAccountHandleToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :glossia_account_handle, :string
    end

    create index(:organizations, [:glossia_account_handle])
  end
end
