defmodule Glossia.Repo.Migrations.CreateKits do
  use Ecto.Migration

  def change do
    create table(:kits, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :handle, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :source_language, :string, null: false
      add :target_languages, {:array, :string}, default: [], null: false
      add :domain_tags, {:array, :string}, default: [], null: false
      add :visibility, :string, default: "public", null: false
      add :stars_count, :integer, default: 0, null: false

      timestamps()
    end

    create unique_index(:kits, [:account_id, :handle])
    create index(:kits, [:account_id])
    create index(:kits, [:visibility])

    create table(:kit_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :kit_id, references(:kits, type: :binary_id, on_delete: :delete_all), null: false
      add :source_term, :string, null: false
      add :definition, :text
      add :tags, {:array, :string}, default: [], null: false

      timestamps()
    end

    create unique_index(:kit_entries, [:kit_id, :source_term])
    create index(:kit_entries, [:kit_id])

    create table(:kit_entry_translations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :kit_entry_id, references(:kit_entries, type: :binary_id, on_delete: :delete_all),
        null: false

      add :language, :string, null: false
      add :translated_term, :string, null: false
      add :usage_note, :text

      timestamps()
    end

    create unique_index(:kit_entry_translations, [:kit_entry_id, :language])
    create index(:kit_entry_translations, [:kit_entry_id])

    create table(:kit_stars, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :kit_id, references(:kits, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create unique_index(:kit_stars, [:kit_id, :user_id])
    create index(:kit_stars, [:kit_id])
    create index(:kit_stars, [:user_id])
  end
end
