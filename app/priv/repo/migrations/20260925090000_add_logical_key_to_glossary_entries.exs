defmodule Glossia.Repo.Migrations.AddLogicalKeyToGlossaryEntries do
  use Ecto.Migration

  def change do
    alter table(:glossary_entries) do
      add :logical_key, :string
    end

    execute(
      "UPDATE glossary_entries SET logical_key = term WHERE logical_key IS NULL",
      ""
    )

    alter table(:glossary_entries) do
      modify :logical_key, :string, null: false
    end

    create unique_index(:glossary_entries, [:glossary_id, :logical_key])
  end
end
