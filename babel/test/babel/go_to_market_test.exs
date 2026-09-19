defmodule Babel.GoToMarketTest do
  use Babel.DataCase, async: true

  alias Babel.GoToMarket
  alias Babel.Organizations

  test "tracks organization state and its interaction timeline" do
    organization_id = Ecto.UUID.generate()

    assert {:ok, organization} =
             Organizations.create_organization(%{
               name: "Example company",
               website_url: "https://example.com",
               state: "qualified",
               translation_tool: "Example translation tool",
               glossia_organization_id: organization_id
             })

    assert organization.glossia_organization_id == organization_id

    occurred_at = DateTime.utc_now(:second)

    assert {:ok, interaction} =
             Organizations.create_interaction(organization, %{
               organization_id: organization.id,
               kind: "research",
               summary: "Reviewed a public customer story.",
               source_url: "https://example.com/customer-story",
               occurred_at: occurred_at
             })

    assert retrieved_organization = Organizations.get_organization(organization.id)
    assert [retrieved_interaction] = retrieved_organization.interactions
    assert retrieved_interaction.id == interaction.id
    assert retrieved_interaction.occurred_at == occurred_at
    assert Organizations.summary().qualified == 1
  end

  test "filters and sorts organizations" do
    assert {:ok, _account} =
             Organizations.create_organization(%{
               name: "Aster Labs",
               website_url: "https://aster.example.com",
               state: "researching",
               notes: "A developer-led localization workflow."
             })

    assert {:ok, _account} =
             Organizations.create_organization(%{
               name: "Zenith Labs",
               website_url: "https://zenith.example.com",
               state: "qualified",
               notes: "A developer-led localization workflow."
             })

    assert {:ok, _account} =
             Organizations.create_organization(%{
               name: "Beta Labs",
               website_url: "https://beta.example.com",
               state: "qualified",
               notes: "A developer-led localization workflow."
             })

    assert ["Zenith Labs", "Beta Labs"] =
             Organizations.list_organizations(
               state: "qualified",
               sort_by: "name",
               sort_order: "desc"
             )
             |> Enum.map(& &1.name)

    assert ["Aster Labs"] =
             Organizations.list_organizations(search: "Aster")
             |> Enum.map(& &1.name)
  end

  test "stores only new public-source discovery results" do
    searcher = fn _query ->
      {:ok,
       [
         %{
           source_url: "https://example.com/customer-story",
           title: "Example company customer story",
           evidence: "A public customer story describes a localization workflow."
         }
       ]}
    end

    assert {:ok, %{created: 1, already_known: 0}} = GoToMarket.discover_new_prospects(searcher)
    assert {:ok, %{created: 0, already_known: 1}} = GoToMarket.discover_new_prospects(searcher)

    [organization] = Organizations.list_organizations(state: "researching")
    assert organization.website_url == "https://example.com/customer-story"
    assert organization.origin_url == "https://example.com/customer-story"

    assert [%{kind: "research", source_url: "https://example.com/customer-story"}] =
             Organizations.get_organization(organization.id).interactions
  end

  test "creates public-source research and summarizes its review stage" do
    assert {:ok, researching} = GoToMarket.create_prospect(prospect_attributes())

    assert researching.status == "researching"

    assert GoToMarket.prospect_summary() == %{
             total: 1,
             researching: 1,
             ready: 0,
             demos_booked: 0
           }

    assert {:ok, updated} = GoToMarket.update_prospect(researching, %{status: "ready"})
    assert updated.status == "ready"
    assert GoToMarket.prospect_summary().ready == 1
  end

  test "requires secure public-source web addresses" do
    assert {:error, changeset} =
             GoToMarket.create_prospect(
               prospect_attributes(%{source_url: "http://example.com/customer-story"})
             )

    assert {"must be a secure web address", []} == changeset.errors[:source_url]
  end

  defp prospect_attributes(overrides \\ %{}) do
    defaults = %{
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

    Map.merge(defaults, overrides)
  end
end
