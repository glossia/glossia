defmodule Glossia.Repo.Migrations.AllowNullModelOnLLMModels do
  use Ecto.Migration

  def change do
    alter table(:llm_models) do
      modify :model, :string, null: true, from: {:string, null: false}
    end
  end
end
