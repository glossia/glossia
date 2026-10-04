defmodule Glossia.Repo.Migrations.CreateTranslationTokenUsage do
  use Ecto.Migration

  def change do
    create table(:translation_token_usage, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false
      add :project_id, references(:projects, type: :uuid, on_delete: :nilify_all)
      add :model, :text, null: false
      add :model_handle, :text
      add :locale, :text
      add :source_path, :text
      add :input_tokens, :bigint, null: false
      add :output_tokens, :bigint, null: false
      add :cached_tokens, :bigint, null: false, default: 0
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:translation_token_usage, [:account_id, :inserted_at])
    create index(:translation_token_usage, [:account_id, :model, :inserted_at])
    create index(:translation_token_usage, [:project_id])

    create constraint(:translation_token_usage, :nonnegative_token_counts,
             check:
               "input_tokens >= 0 AND output_tokens >= 0 AND cached_tokens >= 0 AND cached_tokens <= input_tokens"
           )
  end
end
