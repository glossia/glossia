defmodule Glossia.Admin.MCP.Server do
  use Hermes.Server,
    name: "Glossia Admin",
    version: "1.0.0",
    capabilities: [:tools]

  component(Glossia.Admin.MCP.ListUsersTool, name: "list_users")
  component(Glossia.Admin.MCP.GetUserTool, name: "get_user")
  component(Glossia.Admin.MCP.GrantAccessTool, name: "grant_access")
  component(Glossia.Admin.MCP.RevokeAccessTool, name: "revoke_access")
  component(Glossia.Admin.MCP.ListAccountsTool, name: "list_accounts")
  component(Glossia.Admin.MCP.SetSuperAdminTool, name: "set_super_admin")
  component(Glossia.Admin.MCP.ListTicketsTool, name: "list_tickets")
  component(Glossia.Admin.MCP.GetTicketTool, name: "get_ticket")
  component(Glossia.Admin.MCP.ReplyTicketTool, name: "reply_ticket")
  component(Glossia.Admin.MCP.UpdateTicketStatusTool, name: "update_ticket_status")
end
