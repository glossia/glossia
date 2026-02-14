defmodule Glossia.Repo.Migrations.CreateVoices do
  use Ecto.Migration

  def change do
    create table(:voices, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :version, :integer, null: false
      add :tone, :string
      add :formality, :string
      add :target_audience, :text
      add :guidelines, :text
      add :change_note, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:voices, [:account_id, :version])
    create index(:voices, [:account_id])

    create table(:voice_overrides, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :voice_id, references(:voices, type: :binary_id, on_delete: :delete_all), null: false

      add :locale, :string, null: false
      add :tone, :string
      add :formality, :string
      add :target_audience, :text
      add :guidelines, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:voice_overrides, [:voice_id, :locale])
    create index(:voice_overrides, [:voice_id])
  end
end
