defmodule Babel.MCP.Server do
  @moduledoc false

  use Hermes.Server,
    name: "Babel operations",
    version: "1.0.0",
    capabilities: [:tools]

  component(Babel.MCP.GetOperationsOverviewTool, name: "get_operations_overview")
  component(Babel.MCP.ListWorkItemsTool, name: "list_work_items")
  component(Babel.MCP.ListGoToMarketProspectsTool, name: "list_go_to_market_prospects")
  component(Babel.MCP.GetGoToMarketProspectTool, name: "get_go_to_market_prospect")
  component(Babel.MCP.CreateGoToMarketProspectTool, name: "create_go_to_market_prospect")
  component(Babel.MCP.UpdateGoToMarketProspectTool, name: "update_go_to_market_prospect")
  component(Babel.MCP.ListOrganizationsTool, name: "list_organizations")
  component(Babel.MCP.GetOrganizationTool, name: "get_organization")
  component(Babel.MCP.CreateOrganizationTool, name: "create_organization")
  component(Babel.MCP.UpdateOrganizationTool, name: "update_organization")
  component(Babel.MCP.CreateOrganizationInteractionTool, name: "create_organization_interaction")
  component(Babel.MCP.DiscoverGoToMarketProspectsTool, name: "discover_go_to_market_prospects")
end
