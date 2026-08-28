defmodule Babel.Repo.Migrations.CreateWorkItems do
  use Ecto.Migration

  def change do
    create table(:work_items) do
      add :area, :string, null: false
      add :assignee, :string
      add :due_on, :date
      add :priority, :string, null: false
      add :status, :string, null: false
      add :summary, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:work_items, [:area])
    create index(:work_items, [:status])
    create index(:work_items, [:due_on])
  end
end
