defmodule Glossia.Repo.Migrations.AddErrorMessageToGitEvents do
  use Ecto.Migration

  def change do
    alter table(:git_events) do
      add :error_message, :string, null: true
    end
  end
end
