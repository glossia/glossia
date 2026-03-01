defmodule Glossia.Repo.Migrations.RenameTicketsToDiscussions do
  use Ecto.Migration

  def change do
    rename table(:ticket_comments), :ticket_id, to: :discussion_id

    rename table(:tickets), to: table(:discussions)
    rename table(:ticket_comments), to: table(:discussion_comments)

    drop_if_exists index(:tickets, [:account_id])
    drop_if_exists index(:tickets, [:user_id])
    drop_if_exists index(:tickets, [:project_id])
    drop_if_exists index(:tickets, [:status])
    drop_if_exists unique_index(:tickets, [:account_id, :number])

    drop_if_exists index(:ticket_comments, [:ticket_id])
    drop_if_exists index(:ticket_comments, [:user_id])

    create index(:discussions, [:account_id])
    create index(:discussions, [:user_id])
    create index(:discussions, [:project_id])
    create index(:discussions, [:status])
    create index(:discussions, [:kind])
    create unique_index(:discussions, [:account_id, :number])

    create index(:discussion_comments, [:discussion_id])
    create index(:discussion_comments, [:user_id])
  end
end
