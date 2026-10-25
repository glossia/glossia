defmodule Glossia.Repo.Migrations.AddTokiTranslationOrigin do
  use Ecto.Migration

  def change do
    alter table(:toki_conversations) do
      # No cascading FK: deletion must not erase the origin and turn a retry
      # into an unlinked conversation. Missing sources fail closed at use time.
      add :translation_session_id, :uuid
    end
  end
end
