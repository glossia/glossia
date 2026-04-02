defmodule Glossia.Repo.Migrations.ConsolidateLlmModelFields do
  use Ecto.Migration

  def change do
    alter table(:llm_models) do
      add :model, :string
    end

    flush()

    execute(
      "UPDATE llm_models SET model = provider || ':' || model_id",
      "UPDATE llm_models SET provider = split_part(model, ':', 1), model_id = split_part(model, ':', 2)"
    )

    alter table(:llm_models) do
      remove :provider, :string
      remove :model_id, :string
    end

    alter table(:llm_models) do
      modify :model, :string, null: false
    end
  end
end
