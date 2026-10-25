defmodule Glossia.Repo.Migrations.CreateLinguisticReviews do
  use Ecto.Migration

  def change do
    create table(:linguistic_reviews, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :translation_session_id,
          references(:translation_sessions, type: :uuid, on_delete: :delete_all),
          null: false

      add :answered_by_id, references(:users, type: :uuid, on_delete: :nilify_all)

      add :resumed_session_id,
          references(:translation_sessions, type: :uuid, on_delete: :nilify_all)

      add :source_path, :text, null: false
      add :output_path, :text, null: false
      add :locale, :text, null: false
      add :fingerprint, :text, null: false
      add :reason, :text, null: false
      add :question, :text, null: false
      add :source_excerpt, :text, null: false
      add :translation_excerpt, :text, null: false
      add :status, :text, null: false, default: "open"
      add :answer, :text
      add :guidance, :text
      add :context_path, :text
      add :context_digest, :text
      add :context_targets, :map, null: false, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(
             :linguistic_reviews,
             [:translation_session_id, :output_path, :locale, :fingerprint],
             name: :linguistic_review_item
           )

    create index(:linguistic_reviews, [:translation_session_id, :status])

    create constraint(:linguistic_reviews, :linguistic_review_status,
             check: "status IN ('open', 'answered', 'stale')"
           )
  end
end
