defmodule Glossia.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text, null: false
      add :type, :string, null: false, default: "issue"
      add :status, :string, null: false, default: "open"

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :resolved_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :resolved_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:tickets, [:account_id])
    create index(:tickets, [:user_id])
    create index(:tickets, [:status])

    create table(:ticket_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :text, null: false
      add :is_staff, :boolean, null: false, default: false
      add :ticket_id, references(:tickets, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ticket_messages, [:ticket_id])
    create index(:ticket_messages, [:user_id])
  end
end
