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

  component(Babel.MCP.CreateClaimableGlossiaOrganizationTool,
    name: "create_claimable_glossia_organization"
  )

  component(Babel.MCP.TransferClaimableGlossiaOrganizationTool,
    name: "transfer_claimable_glossia_organization"
  )

  component(Babel.MCP.CreateOrganizationInteractionTool, name: "create_organization_interaction")
  component(Babel.MCP.DiscoverGoToMarketProspectsTool, name: "discover_go_to_market_prospects")

  component(Babel.MCP.ListErrorIssuesTool, name: "list_error_issues")
  component(Babel.MCP.GetErrorIssueTool, name: "get_error_issue")
  component(Babel.MCP.ListErrorEventsTool, name: "list_error_events")
  component(Babel.MCP.GetErrorEventTool, name: "get_error_event")
  component(Babel.MCP.ResolveErrorIssueTool, name: "resolve_error_issue")
  component(Babel.MCP.UnresolveErrorIssueTool, name: "unresolve_error_issue")
  component(Babel.MCP.IgnoreErrorIssueTool, name: "ignore_error_issue")
  component(Babel.MCP.GetOrganizationErrorDsnTool, name: "get_organization_error_dsn")
  component(Babel.MCP.RotateOrganizationErrorDsnTool, name: "rotate_organization_error_dsn")
end
