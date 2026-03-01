defmodule Glossia.Repo.Migrations.RemoveKitStarsCount do
  use Ecto.Migration

  def change do
    alter table(:kits) do
      remove :stars_count, :integer, default: 0, null: false
    end
  end
end
