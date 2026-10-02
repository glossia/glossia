%{
  title: "Authorization",
  summary: "Permission scopes, organization roles, and resource-level access checks.",
  category: "reference",
  subcategory: "apis",
  order: 2
}
---

Authentication establishes an identity; authorization decides which actions that identity can perform. See [Authentication](/docs/reference/apis/authentication) for sign-in and token flows.

## Scopes

Scopes control what actions a token can perform. They follow the `object:action` pattern.

| Scope | Description |
|-------|-------------|
| `admin:read` | Read platform administration data (platform administrators only) |
| `admin:write` | Update platform administration data (platform administrators only) |
| `ops:read` | Read platform operations data (platform administrators only) |
| `user:read` | Read user profile information |
| `user:write` | Update user profile |
| `account:read` | List organization accounts you can access |
| `organization:read` | Read organization details (and list your organizations) |
| `organization:write` | Create or update organizations |
| `organization:claim` | Claim an organization |
| `organization:delete` | Delete organizations |
| `organization:admin` | Administrative organization actions |
| `members:read` | Read organization members and invitations |
| `members:write` | Manage organization members and invitations |
| `project:read` | Read projects |
| `project:write` | Create or update projects |
| `project:admin` | Administrative project actions |
| `project:delete` | Delete projects |
| `voice:read` | Read voice configuration |
| `voice:write` | Create or update voice configuration |
| `voice:admin` | Administrative voice actions |
| `glossary:read` | Read glossary entries |
| `glossary:write` | Create or update glossary entries |
| `glossary:admin` | Manage glossary settings |
| `discussion:read` | Read discussions |
| `discussion:write` | Create or update discussions |
| `discussion:admin` | Administrative discussion actions |
| `ticket:read` | Read tickets |
| `ticket:write` | Create or update tickets |
| `ticket:admin` | Administrative ticket actions |
| `llm_model:read` | Read account language models |
| `llm_model:write` | Manage account language models |
| `translation:write` | Write translation data |
| `api_credentials:read` | Read access credentials |
| `api_credentials:write` | Manage access credentials |

The authentication server's [discovery metadata](/docs/reference/apis/authentication#discovery-endpoints) publishes the scopes available to clients. A scope being available does not grant access by itself.

## Authorization model

Glossia enforces **two layers** for the [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) application programming interface and the [Model Context Protocol](https://modelcontextprotocol.io) server:

1. **Scope check**: the access token must include the required `object:action` scope.
2. **Resource-level policy**: the current user must be authorized for the specific resource through explicit member permissions or the role-based policy.

Scopes represent the *maximum* capability of a token. Resource-level checks enforce the *actual* permission for a specific resource.

### Roles

| Role | Description |
|------|-------------|
| `self` | The user accessing their own resources |
| `organization_member` | A member of the organization that owns the resource |
| `organization_admin` | An administrator of the organization that owns the resource |
| `public_account` | The resource belongs to a public account |

### Member permissions

Non-administrator organization memberships can carry explicit permission scopes. New members start with read access to the account, organization, projects, voice, glossary, discussions, and tickets. An organization administrator can replace those scopes through [Members → Permissions](/docs/how-to/member-permissions). A requested action must be included in the member's allowed scopes as well as the token's scopes when using a token.

Organization administrators retain their administrator role. Existing memberships without explicit scopes continue to use the role-based policy below until permissions are saved.

### Role permissions

The table below shows common role-based rules for memberships without explicit scopes. It is not the complete policy: collection requests, temporary access, and platform administrators have additional rules.

| Scope | self | organization_member | organization_admin | public_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Yes | Yes | | |
| `user:write` | Yes | | | |
| `account:read` | | Yes | Yes | Yes |
| `organization:read` | | Yes | Yes | |
| `organization:write` | | | Yes | |
| `organization:delete` | | | Yes | |
| `organization:admin` | | | Yes | |
| `members:read` | | Yes | Yes | |
| `members:write` | | | Yes | |
| `project:read` | | Yes | Yes | Yes |
| `project:write` | | | Yes | |
| `project:admin` | | | Yes | |
| `project:delete` | | | Yes | |
| `voice:read` | | Yes | Yes | Yes |
| `voice:write` | | | Yes | |
| `voice:admin` | | | Yes | |
| `glossary:read` | | Yes | Yes | |
| `glossary:write` | | | Yes | |
| `glossary:admin` | | | Yes | |

