defmodule Babel.Organizations.DirectoryTest do
  use Babel.DataCase, async: true

  alias Babel.Organizations
  alias Babel.Organizations.DirectoryCache

  test "reconciles Glossia organizations with Babel leads" do
    glossia_organization_id = Ecto.UUID.generate()

    {:ok, connected_organization} =
      Organizations.create_organization(%{
        name: "Babel name",
        website_url: "https://connected.example.com",
        state: "customer",
        glossia_organization_id: glossia_organization_id
      })

    {:ok, lead_organization} =
      Organizations.create_organization(%{
        name: "Uncreated lead",
        website_url: "https://lead.example.com",
        state: "researching"
      })

    cache = start_directory_cache()
    production_only_id = Ecto.UUID.generate()

    query = fn sql, opts ->
      assert sql =~ "SELECT organizations.id::text AS organization_id, organizations.name"
      assert opts == [limit: 200]

      {:ok,
       %{
         "rows" => [
           %{"organization_id" => glossia_organization_id, "name" => "Glossia name"},
           %{"organization_id" => production_only_id, "name" => "Production only"}
         ]
       }}
    end

    assert Organizations.directory(query: query, cache: cache) == [
             %{
               id: "glossia-#{glossia_organization_id}",
               name: "Glossia name",
               source: :glossia,
               organization: connected_organization
             },
             %{
               id: "glossia-#{production_only_id}",
               name: "Production only",
               source: :glossia,
               organization: nil
             },
             %{
               id: "lead-#{lead_organization.id}",
               name: lead_organization.name,
               source: :lead,
               organization: lead_organization
             }
           ]
  end

  test "uses locally linked organizations when Glossia is unavailable" do
    glossia_organization_id = Ecto.UUID.generate()

    {:ok, connected_organization} =
      Organizations.create_organization(%{
        name: "Connected organization",
        website_url: "https://connected.example.com",
        state: "customer",
        glossia_organization_id: glossia_organization_id
      })

    {:ok, lead_organization} =
      Organizations.create_organization(%{
        name: "Lead organization",
        website_url: "https://lead.example.com",
        state: "researching"
      })

    assert Organizations.directory(
             query: fn _sql, _opts -> {:error, :unavailable} end,
             cache: start_directory_cache()
           ) == [
             %{
               id: "glossia-#{glossia_organization_id}",
               name: connected_organization.name,
               source: :glossia,
               organization: connected_organization
             },
             %{
               id: "lead-#{lead_organization.id}",
               name: lead_organization.name,
               source: :lead,
               organization: lead_organization
             }
           ]
  end

  defp start_directory_cache do
    name = :"organization_directory_cache_#{System.unique_integer([:positive])}"
    start_supervised!({DirectoryCache, name: name})
    name
  end
end
