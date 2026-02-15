defmodule Glossia.Repo.Migrations.AddDescriptionAndCountriesToVoices do
  use Ecto.Migration

  def change do
    alter table(:voices) do
      add :description, :text
      add :target_countries, {:array, :text}, default: []
      add :country_contexts, :map, default: %{}
    end
  end
end
