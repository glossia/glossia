defmodule Babel.MCP.OrganizationInteractionSerializer do
  @moduledoc false

  def serialize(interaction) do
    %{
      id: interaction.id,
      organization_id: interaction.organization_id,
      kind: interaction.kind,
      summary: interaction.summary,
      body: interaction.body,
      source_url: interaction.source_url,
      occurred_at: DateTime.to_iso8601(interaction.occurred_at)
    }
  end
end
