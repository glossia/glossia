defmodule Glossia.Repo.Migrations.AddPublicationFieldsToTranslationSessions do
  use Ecto.Migration

  def change do
    alter table(:translation_sessions) do
      add :publication_branch, :string
      add :publication_commit_sha, :string
      add :pull_request_url, :string
    end
  end
end
