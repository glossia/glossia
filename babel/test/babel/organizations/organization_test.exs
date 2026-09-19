defmodule Babel.Organizations.OrganizationTest do
  use Babel.DataCase, async: true

  alias Babel.Organizations
  alias Babel.Organizations.Organization

  test "stores an optional secure origin and derives the website favicon" do
    assert {:ok, organization} =
             Organizations.create_organization(%{
               name: "Example company",
               website_url: "https://example.com/products/localization",
               origin_url: "https://example.com/customer-story"
             })

    assert organization.origin_url == "https://example.com/customer-story"
    assert Organizations.favicon_url(organization) == "https://example.com/favicon.ico"
  end

  test "rejects an insecure origin" do
    changeset =
      Organization.changeset(%Organization{}, %{
        name: "Example company",
        website_url: "https://example.com",
        origin_url: "http://example.com/customer-story"
      })

    assert {"must be a secure web address", []} == changeset.errors[:origin_url]
  end

  test "creates a claimable Glossia organization and records its reference" do
    suffix = System.unique_integer([:positive])
    name = "Omarchy #{suffix}"
    website_url = "https://omarchy-#{suffix}.org"

    {:ok, organization} =
      Organizations.create_organization(%{
        name: name,
        website_url: website_url
      })

    requester = %{email: "operator@glossia.ai", pomerium_id: "google/operator"}
    organization_id = Ecto.UUID.generate()

    client = fn attributes, [] ->
      assert attributes == %{
               "handle" => "omarchy",
               "name" => name,
               "requested_by_email" => "operator@glossia.ai",
               "requested_by_pomerium_id" => "google/operator"
             }

      {:ok, %{"id" => organization_id, "handle" => "omarchy", "claimable" => true}}
    end

    assert {:ok, updated_organization} =
             Organizations.create_claimable_glossia_organization(
               organization,
               requester,
               "omarchy",
               client: client
             )

    assert updated_organization.glossia_organization_id == organization_id
    assert updated_organization.glossia_account_handle == "omarchy"
    assert updated_organization.glossia_claimable

    assert [interaction] = Organizations.get_organization(updated_organization.id).interactions
    assert interaction.summary == "Created claimable Glossia organization \"omarchy\"."
  end

  test "transfers a connected claimable Glossia organization to an existing user" do
    suffix = System.unique_integer([:positive])

    {:ok, organization} =
      Organizations.create_organization(%{
        name: "Omarchy #{suffix}",
        website_url: "https://omarchy-#{suffix}.org",
        glossia_organization_id: Ecto.UUID.generate(),
        glossia_account_handle: "omarchy",
        glossia_claimable: true
      })

    requester = %{email: "operator@glossia.ai", pomerium_id: "google/operator"}

    client = fn handle, attributes, [] ->
      assert handle == "omarchy"

      assert attributes == %{
               "email" => "maintainer@omarchy.org",
               "requested_by_email" => "operator@glossia.ai",
               "requested_by_pomerium_id" => "google/operator"
             }

      {:ok, %{"claimable" => false}}
    end

    assert {:ok, transferred_organization} =
             Organizations.transfer_claimable_glossia_organization(
               organization,
               requester,
               "maintainer@omarchy.org",
               client: client
             )

    refute transferred_organization.glossia_claimable

    assert [interaction] = Organizations.get_organization(organization.id).interactions

    assert interaction.summary ==
             "Transferred claimable Glossia organization ownership to maintainer@omarchy.org."

    refute Organizations.get_organization(organization.id).glossia_claimable
  end
end
