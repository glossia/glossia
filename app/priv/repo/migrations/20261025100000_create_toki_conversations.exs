defmodule Glossia.Repo.Migrations.CreateTokiConversations do
  use Ecto.Migration

  def change do
    create table(:toki_conversations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :project_id, references(:projects, type: :uuid, on_delete: :delete_all), null: false
      add :title, :text, null: false, default: "New conversation"
      add :status, :text, null: false, default: "completed"
      add :error, :text
      timestamps(type: :utc_datetime_usec)
    end

    create index(:toki_conversations, [:user_id, :project_id, :updated_at, :id])
    create index(:toki_conversations, [:user_id, :status])

    create constraint(:toki_conversations, :toki_conversation_status,
             check: "status IN ('queued', 'running', 'completed', 'failed')"
           )

    create table(:toki_messages, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :conversation_id,
          references(:toki_conversations, type: :uuid, on_delete: :delete_all),
          null: false

      add :role, :text, null: false
      add :content, :text, null: false
      add :status, :text, null: false
      add :reply_to_id, references(:toki_messages, type: :uuid, on_delete: :delete_all)
      timestamps(type: :utc_datetime_usec)
    end

    create index(:toki_messages, [:conversation_id, :inserted_at, :id])
    create index(:toki_messages, [:status, :updated_at])
    create unique_index(:toki_messages, [:reply_to_id])

    create constraint(:toki_messages, :toki_message_role, check: "role IN ('user', 'assistant')")

    create constraint(:toki_messages, :toki_message_status,
             check: "status IN ('queued', 'running', 'completed', 'failed')"
           )
  end
end
