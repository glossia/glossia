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
  component(Glossia.Admin.MCP.ListDiscussionsTool, name: "list_discussions")
  component(Glossia.Admin.MCP.GetDiscussionTool, name: "get_discussion")
  component(Glossia.Admin.MCP.CommentDiscussionTool, name: "comment_discussion")
  component(Glossia.Admin.MCP.CloseDiscussionTool, name: "close_discussion")
end
