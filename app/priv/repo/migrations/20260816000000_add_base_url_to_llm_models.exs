defmodule Glossia.Repo.Migrations.AddBaseUrlToLlmModels do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE llm_models ADD COLUMN IF NOT EXISTS base_url varchar(255)",
      "ALTER TABLE llm_models DROP COLUMN IF EXISTS base_url"
    )
  end
end
