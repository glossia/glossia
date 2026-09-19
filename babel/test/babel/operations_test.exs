defmodule Babel.OperationsTest do
  use Babel.DataCase, async: true

  alias Babel.Operations
  alias Babel.Operations.WorkItem

  test "summarizes operational work" do
    today = Date.utc_today()

    insert_work_item!(%{status: "Open", due_on: Date.add(today, 2)})
    insert_work_item!(%{status: "Blocked", due_on: Date.add(today, 5)})
    insert_work_item!(%{status: "Done", due_on: Date.add(today, -1)})

    dashboard = Operations.dashboard()

    assert dashboard.open_count == 2
    assert dashboard.blocked_count == 1
    assert dashboard.due_this_week_count == 2
    assert dashboard.completed_count == 1
  end

  defp insert_work_item!(attributes) do
    defaults = %{
      area: "Operations",
      assignee: "Babel",
      due_on: nil,
      priority: "Normal",
      status: "Open",
      summary: "Work item #{System.unique_integer([:positive])}"
    }

    %WorkItem{}
    |> WorkItem.changeset(Map.merge(defaults, attributes))
    |> Repo.insert!()
  end
end
