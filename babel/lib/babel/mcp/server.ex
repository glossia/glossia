defmodule Babel.MCP.Server do
  @moduledoc false

  use Hermes.Server,
    name: "Babel operations",
    version: "1.0.0",
    capabilities: [:tools]

  component(Babel.MCP.GetOperationsOverviewTool, name: "get_operations_overview")
  component(Babel.MCP.ListWorkItemsTool, name: "list_work_items")
end
