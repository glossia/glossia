defmodule Babel.MCP.GoToMarketProspectSerializer do
  @moduledoc false

  def serialize(prospect) do
    %{
      id: prospect.id,
      company: prospect.company,
      website_url: prospect.website_url,
      translation_tool: prospect.translation_tool,
      source_title: prospect.source_title,
      source_url: prospect.source_url,
      evidence: prospect.evidence,
      contact_name: prospect.contact_name,
      contact_role: prospect.contact_role,
      contact_profile_url: prospect.contact_profile_url,
      status: prospect.status,
      outreach_angle: prospect.outreach_angle,
      intro_email_draft: prospect.intro_email_draft,
      next_step: prospect.next_step,
      organization_id: prospect.organization_id
    }
  end
end
