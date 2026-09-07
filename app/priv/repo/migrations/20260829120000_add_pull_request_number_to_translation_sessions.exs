defmodule Glossia.Repo.Migrations.AddPullRequestNumberToTranslationSessions do
  use Ecto.Migration

  def change do
    alter table(:translation_sessions) do
      add :pull_request_number, :integer
    end
  end
end
