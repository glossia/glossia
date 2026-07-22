defmodule Glossia.Repo.Migrations.UseCanonicalModelIdentifiers do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE llm_models
    SET model = split_part(model, ':', 1) || '/' ||
      substring(model FROM position(':' IN model) + 1)
    WHERE position(':' IN model) > 0
    """)
  end

  def down do
    execute("""
    UPDATE llm_models
    SET model = split_part(model, '/', 1) || ':' ||
      substring(model FROM position('/' IN model) + 1)
    WHERE position('/' IN model) > 0
    """)
  end
end
