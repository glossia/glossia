defmodule Glossia.MCP.Server do
  use Hermes.Server,
    name: "Glossia",
    version: "1.0.0",
    capabilities: [:tools]

  component Glossia.MCP.CreateOrganizationTool, name: "create_organization"
end
