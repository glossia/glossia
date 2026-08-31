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
end
