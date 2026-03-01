defmodule Glossia.Repo.Migrations.AddChangeRequestFieldsToTickets do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :kind, :string, null: false, default: "general"
      add :metadata, :map, null: false, default: %{}
    end

    create index(:tickets, [:kind])
  end
end
