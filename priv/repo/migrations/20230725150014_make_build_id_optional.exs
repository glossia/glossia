defmodule Glossia.Foundation.Database.Core.Repo.Migrations.MakeBuildIdOptional do
  use Ecto.Migration

  def change do
    drop index("translations", [:build_id])

    alter table("translations") do
      remove :build_id
    end

    alter table("translations") do
      add :build_id, :string, null: true
    end

    create index(:translations, [:build_id])
  end
end
