defmodule Glossia.Repo.Migrations.CreateGlossaries do
  use Ecto.Migration

  def change do
    create table(:glossaries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :version, :bigint, null: false
      add :change_note, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:glossaries, [:account_id, :version])
    create index(:glossaries, [:account_id])

    create table(:glossary_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :glossary_id, references(:glossaries, type: :binary_id, on_delete: :delete_all),
        null: false

      add :term, :string, null: false
      add :definition, :text
      add :case_sensitive, :boolean, default: false, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:glossary_entries, [:glossary_id, :term])
    create index(:glossary_entries, [:glossary_id])

    create table(:glossary_translations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :glossary_entry_id,
          references(:glossary_entries, type: :binary_id, on_delete: :delete_all),
          null: false

      add :locale, :string, null: false
      add :translation, :string, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:glossary_translations, [:glossary_entry_id, :locale])
    create index(:glossary_translations, [:glossary_entry_id])
  end
end
