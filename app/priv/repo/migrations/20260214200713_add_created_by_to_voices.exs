defmodule Glossia.Repo.Migrations.AddCreatedByToVoices do
  use Ecto.Migration

  def change do
    alter table(:voices) do
      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    end
  end
end
