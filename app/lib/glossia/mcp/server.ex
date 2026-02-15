defmodule Glossia.MCP.Server do
  use Hermes.Server,
    name: "Glossia",
    version: "1.0.0",
    capabilities: [:tools]

  component(Glossia.MCP.ListAccountsTool, name: "list_accounts")
  component(Glossia.MCP.ListProjectsTool, name: "list_projects")
  component(Glossia.MCP.CreateOrganizationTool, name: "create_organization")
  component(Glossia.MCP.ListOrganizationsTool, name: "list_organizations")
  component(Glossia.MCP.GetOrganizationTool, name: "get_organization")
  component(Glossia.MCP.UpdateOrganizationTool, name: "update_organization")
  component(Glossia.MCP.DeleteOrganizationTool, name: "delete_organization")
  component(Glossia.MCP.ListOrganizationMembersTool, name: "list_organization_members")
  component(Glossia.MCP.RemoveOrganizationMemberTool, name: "remove_organization_member")
  component(Glossia.MCP.InviteOrganizationMemberTool, name: "invite_organization_member")
  component(Glossia.MCP.ListOrganizationInvitationsTool, name: "list_organization_invitations")
  component(Glossia.MCP.RevokeOrganizationInvitationTool, name: "revoke_organization_invitation")
  component(Glossia.MCP.GetVoiceTool, name: "get_voice")
  component(Glossia.MCP.SaveVoiceTool, name: "save_voice")
  component(Glossia.MCP.GetGlossaryTool, name: "get_glossary")
  component(Glossia.MCP.SaveGlossaryTool, name: "save_glossary")
  component(Glossia.MCP.ListTokensTool, name: "list_tokens")
  component(Glossia.MCP.CreateTokenTool, name: "create_token")
  component(Glossia.MCP.RevokeTokenTool, name: "revoke_token")
  component(Glossia.MCP.ListOAuthAppsTool, name: "list_oauth_apps")
end
