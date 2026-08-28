defmodule Babel.MCP.GetOperationsOverviewToolTest do
  use Babel.DataCase, async: true

  alias Babel.Accounts.Account
  alias Babel.MCP.GetOperationsOverviewTool
  alias Babel.Operations.WorkItem
  alias Hermes.Server.Frame

  test "returns operational totals and the work queue for an authorized account" do
    account = insert_account!()
    insert_work_item!(%{status: "Open", summary: "Review customer health"})
    insert_work_item!(%{status: "Blocked", summary: "Confirm vendor renewal"})

    frame = Frame.new(current_account: account, scopes: ["operations:read"])

    assert {:reply, response, ^frame} = GetOperationsOverviewTool.execute(%{}, frame)
    assert response.structured_content.open_count == 2
    assert response.structured_content.blocked_count == 1

    assert Enum.map(response.structured_content.work_items, & &1.summary) == [
             "Review customer health",
             "Confirm vendor renewal"
           ]
  end

  test "rejects a token without the operations read scope" do
    frame = Frame.new(current_account: insert_account!(), scopes: [])

    assert {:error, %Hermes.MCP.Error{message: message}, ^frame} =
             GetOperationsOverviewTool.execute(%{}, frame)

    assert message =~ "operations:read"
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

  defp insert_work_item!(attributes) do
    defaults = %{
      area: "Operations",
      assignee: "Babel",
      due_on: Date.add(Date.utc_today(), 1),
      priority: "High",
      status: "Open",
      summary: "Work item #{System.unique_integer([:positive])}"
    }

    %WorkItem{}
    |> WorkItem.changeset(Map.merge(defaults, attributes))
    |> Repo.insert!()
  end
end
