defmodule Glossia.Repo.Migrations.BackfillDefaultLlmModels do
  use Ecto.Migration

  def up do
    execute("""
    WITH first_models AS (
      SELECT DISTINCT ON (account_id) id
      FROM llm_models AS candidate
      WHERE NOT EXISTS (
        SELECT 1
        FROM llm_models AS configured_default
        WHERE configured_default.account_id = candidate.account_id
          AND configured_default."default" = TRUE
      )
      ORDER BY account_id, handle
    )
    UPDATE llm_models AS model
    SET "default" = TRUE
    FROM first_models
    WHERE model.id = first_models.id
    """)
  end

  def down, do: :ok
end
