defmodule Babel.MCP.ListWorkItemsToolTest do
  use Babel.DataCase, async: true

  alias Babel.Accounts.Account
  alias Babel.MCP.ListWorkItemsTool
  alias Babel.Operations.WorkItem
  alias Hermes.Server.Frame

  test "filters the work queue by area" do
    account = insert_account!()
    finance_item = insert_work_item!("Finance", "Review annual budget")
    insert_work_item!("Growth", "Prepare launch cohort")

    frame = Frame.new(current_account: account, scopes: ["operations:read"])

    assert {:reply, response, ^frame} =
             ListWorkItemsTool.execute(%{area: "Finance"}, frame)

    assert response.structured_content.work_items == [
             %{
               id: finance_item.id,
               area: "Finance",
               assignee: "Babel",
               due_on: Date.to_iso8601(finance_item.due_on),
               priority: "Normal",
               status: "Open",
               summary: "Review annual budget"
             }
           ]
  end

  defp insert_account! do
    suffix = System.unique_integer([:positive])

    %Account{}
    |> Account.registration_changeset(%{
      email: "operator-#{suffix}@glossia.ai",
      name: "Operations operator",
      pomerium_id: "google/operator-#{suffix}",
      last_seen_at: DateTime.utc_now(:second)
    })
    |> Repo.insert!()
  end

  defp insert_work_item!(area, summary) do
    %WorkItem{}
    |> WorkItem.changeset(%{
      area: area,
      assignee: "Babel",
      due_on: Date.add(Date.utc_today(), 1),
      priority: "Normal",
      status: "Open",
      summary: summary
    })
    |> Repo.insert!()
  end
end
