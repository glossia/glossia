defmodule BabelWeb.OperationsLiveTest do
  use BabelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Babel.Operations.WorkItem
  alias Babel.Repo

  test "renders the operations dashboard", %{conn: conn} do
    work_item = insert_work_item!("Prepare the customer adoption review", "Blocked")

    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Operations overview"
    assert has_element?(view, "#babel-sidebar")
    assert has_element?(view, "#operations-work-items", work_item.summary)
    assert has_element?(view, "#operations-work-items .noora-status-badge[data-status='error']")
  end

  test "filters customer work in the customer view", %{conn: conn} do
    customer_work_item = insert_work_item!("Follow up on the customer rollout", "In progress")
    insert_work_item!("Review the infrastructure invoice", "Open", "Finance")

    {:ok, view, html} = live(conn, ~p"/customers")

    assert html =~ "Customer operations"
    assert has_element?(view, "#operations-work-items", customer_work_item.summary)
    refute has_element?(view, "#operations-work-items", "Review the infrastructure invoice")
  end

  defp insert_work_item!(summary, status, area \\ "Customer success") do
    %WorkItem{}
    |> WorkItem.changeset(%{
      area: area,
      assignee: "Babel",
      due_on: Date.add(Date.utc_today(), 1),
      priority: "High",
      status: status,
      summary: summary <> " #{System.unique_integer([:positive])}"
    })
    |> Repo.insert!()
  end
end
