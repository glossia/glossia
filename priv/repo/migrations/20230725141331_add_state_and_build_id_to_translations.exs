defmodule Glossia.Foundation.Database.Core.Repo.Migrations.AddStateAndBuildIdToTranslations do
  use Ecto.Migration

  def change do
    alter table(:translations) do
      add :status, :integer, default: 1, null: false
      add :build_id, :string, null: false
    end

    create index(:translations, [:status])
    create index(:translations, [:build_id])
  end
end
