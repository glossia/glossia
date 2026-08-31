defmodule Babel.MCP.GoToMarketProspectsToolTest do
  use Babel.DataCase, async: true

  alias Babel.Accounts.Account
  alias Babel.MCP.CreateGoToMarketProspectTool
  alias Babel.MCP.GetGoToMarketProspectTool
  alias Babel.MCP.ListGoToMarketProspectsTool
  alias Babel.MCP.UpdateGoToMarketProspectTool
  alias Hermes.Server.Frame

  test "creates, lists, gets, and updates a prospect with the appropriate scopes" do
    account = insert_account!()
    read_frame = Frame.new(current_account: account, scopes: ["operations:read"])
    write_frame = Frame.new(current_account: account, scopes: ["operations:write"])

    assert {:reply, create_response, ^write_frame} =
             CreateGoToMarketProspectTool.execute(prospect_attributes(), write_frame)

    prospect = create_response.structured_content.prospect
    assert prospect.company == "Example company"
    assert prospect.status == "researching"

    assert {:reply, list_response, ^read_frame} =
             ListGoToMarketProspectsTool.execute(%{status: "researching"}, read_frame)

    assert [listed_prospect] = list_response.structured_content.prospects
    assert listed_prospect.id == prospect.id

    assert {:reply, get_response, ^read_frame} =
             GetGoToMarketProspectTool.execute(%{id: prospect.id}, read_frame)

    assert get_response.structured_content.prospect.source_title == "Example customer story"

    assert {:reply, update_response, ^write_frame} =
             UpdateGoToMarketProspectTool.execute(
               %{id: prospect.id, status: "ready"},
               write_frame
             )

    assert update_response.structured_content.prospect.status == "ready"
  end

  test "does not allow a read token to create research" do
    frame = Frame.new(current_account: insert_account!(), scopes: ["operations:read"])

    assert {:error, %Hermes.MCP.Error{message: message}, ^frame} =
             CreateGoToMarketProspectTool.execute(prospect_attributes(), frame)

    assert message =~ "operations:write"
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

  defp prospect_attributes do
    %{
      company: "Example company",
      website_url: "https://example.com",
      translation_tool: "Example translation tool",
      source_title: "Example customer story",
      source_url: "https://example.com/customer-story",
      evidence: "A public customer story describes a localization workflow.",
      contact_name: "Example contact",
      contact_role: "Localization lead",
      status: "researching",
      outreach_angle: "Offer a small developer-led review of one non-production change.",
      next_step: "Confirm the current contact through a public company channel."
    }
  end
end
