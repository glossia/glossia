defmodule Glossia.Repo.Migrations.RenameTicketsToIssues do
  use Ecto.Migration

  def change do
    # 1. Rename tables
    rename table(:tickets), to: table(:issues)
    rename table(:ticket_messages), to: table(:issue_comments)

    # 2. Modify issues table
    alter table(:issues) do
      add :project_id, references(:projects, type: :binary_id, on_delete: :nilify_all)
      remove :type, :string, default: "issue"
    end

    rename table(:issues), :description, to: :body
    rename table(:issues), :resolved_at, to: :closed_at
    rename table(:issues), :resolved_by_id, to: :closed_by_id

    # 3. Normalize statuses
    execute(
      "UPDATE issues SET status = 'closed' WHERE status IN ('in_progress', 'resolved', 'implemented')",
      "SELECT 1"
    )

    # 4. Modify issue_comments table
    alter table(:issue_comments) do
      remove :is_staff, :boolean, default: false
    end

    rename table(:issue_comments), :ticket_id, to: :issue_id

    # 5. Update indexes
    drop_if_exists index(:issues, [:account_id], name: "tickets_account_id_index")
    drop_if_exists index(:issues, [:user_id], name: "tickets_user_id_index")
    drop_if_exists index(:issues, [:status], name: "tickets_status_index")

    drop_if_exists unique_index(:issues, [:account_id, :number],
                     name: "tickets_account_id_number_index"
                   )

    create index(:issues, [:account_id])
    create index(:issues, [:user_id])
    create index(:issues, [:project_id])
    create index(:issues, [:status])
    create unique_index(:issues, [:account_id, :number])

    drop_if_exists index(:issue_comments, [:ticket_id], name: "ticket_messages_ticket_id_index")
    drop_if_exists index(:issue_comments, [:user_id], name: "ticket_messages_user_id_index")

    create index(:issue_comments, [:issue_id])
    create index(:issue_comments, [:user_id])
  end
end
