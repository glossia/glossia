defmodule Glossia.Repo.Migrations.AddLogicalKeyToGlossaryEntries do
  use Ecto.Migration

  # Expand step of an expand/backfill/contract rollout: add the column as
  # nullable, backfill existing rows, and add a partial unique index that
  # only covers rows whose key is set. Old app instances that are still up
  # during the rolling deploy can keep inserting entries with a NULL
  # `logical_key` without hitting a not-null violation. A follow-up
  # migration will backfill again and add the NOT NULL constraint once
  # every writer has been upgraded.
  def change do
    alter table(:glossary_entries) do
      add :logical_key, :string
    end

    execute(
      "UPDATE glossary_entries SET logical_key = term WHERE logical_key IS NULL",
      ""
    )

    create unique_index(:glossary_entries, [:glossary_id, :logical_key],
             where: "logical_key IS NOT NULL",
             name: :glossary_entries_glossary_id_logical_key_index
           )
  end
end
