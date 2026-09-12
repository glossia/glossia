defmodule Glossia.Repo.Migrations.BackfillTranslationConcurrency do
  use Ecto.Migration

  # The migration that adds the `translation_concurrency` column
  # (`20260911140000_add_translation_concurrency_to_llm_models.exs`)
  # picked up its backfill clause AFTER an earlier release already
  # recorded that version as applied. Ecto never re-runs a file whose
  # version is present in `schema_migrations`, so every installation
  # that upgraded through the initial cut kept its `llm_models` rows at
  # `NULL` — the very state the outage-safe default was there to
  # prevent. Run the same backfill as a fresh migration so anyone who
  # walked through that window gets the same safe default.
  def up do
    execute("""
    UPDATE llm_models
    SET translation_concurrency = 5
    WHERE translation_concurrency IS NULL
    """)
  end

  def down, do: :ok
end
