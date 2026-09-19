defmodule Babel.MCP.OrganizationSerializer do
  @moduledoc false

  alias Babel.MCP.OrganizationInteractionSerializer

  def serialize(organization) do
    %{
      id: organization.id,
      name: organization.name,
      website_url: organization.website_url,
      origin_url: organization.origin_url,
      state: organization.state,
      translation_tool: organization.translation_tool,
      notes: organization.notes,
      glossia_organization_id: organization.glossia_organization_id,
      glossia_claimable: organization.glossia_claimable
    }
  end

  def serialize_with_interactions(organization) do
    Map.put(
      serialize(organization),
      :interactions,
      Enum.map(organization.interactions, &OrganizationInteractionSerializer.serialize/1)
    )
  end
end
