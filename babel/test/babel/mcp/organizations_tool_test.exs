defmodule Babel.MCP.OrganizationsToolTest do
  use Babel.DataCase, async: true

  alias Babel.Accounts.Account
  alias Babel.MCP.CreateOrganizationInteractionTool
  alias Babel.MCP.CreateOrganizationTool
  alias Babel.MCP.DiscoverGoToMarketProspectsTool
  alias Babel.MCP.GetOrganizationTool
  alias Babel.MCP.ListOrganizationsTool
  alias Babel.MCP.UpdateOrganizationTool
  alias Hermes.Server.Frame

  test "creates, updates, and retrieves an organization timeline with the appropriate scopes" do
    operator = insert_account!()
    read_frame = Frame.new(current_account: operator, scopes: ["operations:read"])
    write_frame = Frame.new(current_account: operator, scopes: ["operations:write"])

    assert {:reply, create_response, ^write_frame} =
             CreateOrganizationTool.execute(organization_attributes(), write_frame)

    organization = create_response.structured_content.organization
    assert organization.state == "researching"
    assert organization.origin_url == "https://example.com/customer-story"
    assert organization.glossia_organization_id == "1d82348e-0175-4abf-aeb8-3f2e8304c7a1"

    assert {:reply, interaction_response, ^write_frame} =
             CreateOrganizationInteractionTool.execute(
               %{
                 organization_id: organization.id,
                 kind: "research",
                 summary: "Reviewed a public customer story.",
                 source_url: "https://example.com/customer-story"
               },
               write_frame
             )

    assert interaction_response.structured_content.interaction.organization_id == organization.id

    assert {:reply, list_response, ^read_frame} =
             ListOrganizationsTool.execute(%{state: "researching"}, read_frame)

    assert [listed_organization] = list_response.structured_content.organizations
    assert listed_organization.id == organization.id

    assert {:reply, update_response, ^write_frame} =
             UpdateOrganizationTool.execute(
               %{id: organization.id, state: "qualified"},
               write_frame
             )

    assert update_response.structured_content.organization.state == "qualified"

    assert {:reply, get_response, ^read_frame} =
             GetOrganizationTool.execute(%{id: organization.id}, read_frame)

    assert Enum.any?(get_response.structured_content.organization.interactions, fn interaction ->
             interaction.summary == "Reviewed a public customer story."
           end)
  end

  test "queues public-source discovery with a write scope" do
    operator = insert_account!()
    write_frame = Frame.new(current_account: operator, scopes: ["operations:write"])

    assert {:reply, response, ^write_frame} =
             DiscoverGoToMarketProspectsTool.execute(%{}, write_frame)

    assert is_integer(response.structured_content.job_id)
    assert response.structured_content.status in ["available", "scheduled"]
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

  defp organization_attributes do
    %{
      name: "Example company",
      website_url: "https://example.com",
      origin_url: "https://example.com/customer-story",
      state: "researching",
      translation_tool: "Example translation tool",
      glossia_organization_id: "1d82348e-0175-4abf-aeb8-3f2e8304c7a1"
    }
  end
end
