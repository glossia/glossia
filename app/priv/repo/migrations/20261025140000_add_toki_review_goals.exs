defmodule Glossia.Repo.Migrations.AddTokiReviewGoals do
  use Ecto.Migration

  def change do
    alter table(:toki_conversations) do
      modify :user_id, :uuid, null: true, from: {:uuid, null: false}

      add :linguistic_review_id,
          references(:linguistic_reviews, type: :uuid, on_delete: :delete_all)
    end

    create unique_index(:toki_conversations, [:linguistic_review_id])

    create constraint(:toki_conversations, :toki_conversation_ownership,
             check:
               "(linguistic_review_id IS NULL AND user_id IS NOT NULL) OR " <>
                 "(linguistic_review_id IS NOT NULL AND user_id IS NULL)"
           )

    alter table(:toki_messages) do
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
    end

    alter table(:linguistic_reviews) do
      add :resolution_message_id, references(:toki_messages, type: :uuid, on_delete: :nilify_all)
    end

    create table(:linguistic_review_participants, primary_key: false) do
      add :linguistic_review_id,
          references(:linguistic_reviews, type: :uuid, on_delete: :delete_all),
          primary_key: true

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), primary_key: true
      timestamps(type: :utc_datetime_usec)
    end
  end
end
