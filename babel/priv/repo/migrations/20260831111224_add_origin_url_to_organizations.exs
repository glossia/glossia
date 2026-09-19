defmodule Babel.Repo.Migrations.AddOriginUrlToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :origin_url, :string
    end
  end
end
