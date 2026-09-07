defmodule Glossia.Repo.Migrations.RenameIssuesToTickets do
  use Ecto.Migration

  def change do
    rename table(:issue_comments), :issue_id, to: :ticket_id

    rename table(:issues), to: table(:tickets)
    rename table(:issue_comments), to: table(:ticket_comments)

    drop_if_exists index(:issues, [:account_id])
    drop_if_exists index(:issues, [:user_id])
    drop_if_exists index(:issues, [:project_id])
    drop_if_exists index(:issues, [:status])
    drop_if_exists unique_index(:issues, [:account_id, :number])

    drop_if_exists index(:issue_comments, [:issue_id])
    drop_if_exists index(:issue_comments, [:user_id])

    create index(:tickets, [:account_id])
    create index(:tickets, [:user_id])
    create index(:tickets, [:project_id])
    create index(:tickets, [:status])
    create unique_index(:tickets, [:account_id, :number])

    create index(:ticket_comments, [:ticket_id])
    create index(:ticket_comments, [:user_id])
  end
end
