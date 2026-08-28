defmodule Babel.Operations.WorkItem do
  use Ecto.Schema

  import Ecto.Changeset

  schema "work_items" do
    field :area, :string
    field :assignee, :string
    field :due_on, :date
    field :priority, :string
    field :status, :string
    field :summary, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(work_item, attributes) do
    work_item
    |> cast(attributes, [:area, :assignee, :due_on, :priority, :status, :summary])
    |> validate_required([:area, :priority, :status, :summary])
    |> validate_inclusion(:area, ["Customer success", "Finance", "Growth", "Operations"])
    |> validate_inclusion(:priority, ["Low", "Normal", "High", "Urgent"])
    |> validate_inclusion(:status, ["Open", "In progress", "Blocked", "Done"])
  end
end
