defmodule Glossia.Repo.Migrations.AddNumberToTickets do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :number, :integer
    end

    flush()

    execute(
      """
      UPDATE tickets SET number = sub.rn
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY inserted_at) AS rn
        FROM tickets
      ) sub
      WHERE tickets.id = sub.id
      """,
      ""
    )

    alter table(:tickets) do
      modify :number, :integer, null: false
    end

    create unique_index(:tickets, [:account_id, :number])
  end
end
