%{
  title: "Authentication and authorization",
  summary: "How Glossia authenticates users and authorizes API access.",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---

## Authentication methods

Glossia supports two authentication methods depending on the context.

### Browser sessions

When you sign in through the web interface, Glossia uses session-based authentication. You authenticate via a third-party provider (GitHub or GitLab) using the [Assent](https://github.com/pow-auth/assent) library. After a successful sign-in, a session cookie is set and used for subsequent requests.

### Bearer tokens (OAuth 2.1)

For API access (such as from the CLI or other tools), Glossia implements OAuth 2.1 with the authorization code flow and PKCE. Clients obtain a Bearer token and include it in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 flow

### 1. Dynamic client registration

Clients register themselves by calling `POST /oauth/register` with their metadata. This follows [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

The server returns `client_id` and `client_secret`.

### 2. Authorization request

The client redirects the user to `/oauth/authorize` with PKCE parameters:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE is required for all clients.** Only the `S256` challenge method is supported.

### 3. Token exchange

After the user approves, the client exchanges the authorization code for tokens at `POST /oauth/token`:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

The response includes an access token and optionally a refresh token.

### 4. Token refresh

When an access token expires, use the refresh token:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## Scopes

Scopes control what actions a token can perform. They follow the `object:action` pattern.

| Scope | Description |
|-------|-------------|
| `user:read` | Read user profile information |
| `user:write` | Update user profile |
| `account:read` | List accounts you can access (personal and organization accounts) |
| `organization:read` | Read organization details (and list your organizations) |
| `organization:write` | Create or update organizations |
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

## Authorization model

Glossia enforces **two layers** for the REST API and MCP server:

1. **Scope check**: the access token must include the required `object:action` scope.
2. **Resource-level policy**: the current user must be authorized for the specific resource via `Glossia.Policy`.

Scopes represent the *maximum* capability of a token. The policy system enforces the *actual* permission for a specific resource.

Write actions (like `*:write`, `*:delete`, and `*:admin`) are also denied when the user's account does not have access (`accounts.has_access == false`).

### Roles

| Role | Description |
|------|-------------|
| `self` | The user accessing their own resources |
| `organization_member` | A member of the organization that owns the resource |
| `organization_admin` | An administrator of the organization that owns the resource |
| `account_owner` | The owner of the account that owns the resource |
| `public_account` | The account is public (read-only) |
| `no_access` | Denies write actions when the user account has no access |

### Role permissions

| Scope | self | organization_member | organization_admin | account_owner | public_account | no_access* |
|-------|------|----------------------|--------------------|--------------|----------------|------------|
| `user:read` | Yes | Yes | | | | |
| `user:write` | Yes | | | | | |
| `account:read` | | Yes | Yes | Yes | Yes | |
| `organization:read` | | Yes | Yes | | | |
| `organization:write` | | | Yes | | | Yes |
| `organization:delete` | | | Yes | | | Yes |
| `organization:admin` | | | Yes | | | Yes |
| `members:read` | | Yes | Yes | | | |
| `members:write` | | | Yes | | | Yes |
| `project:read` | | Yes | Yes | Yes | Yes | |
| `project:write` | | Yes | Yes | Yes | | Yes |
| `project:admin` | | | Yes | Yes | | Yes |
| `project:delete` | | | Yes | Yes | | Yes |
| `voice:read` | | Yes | Yes | Yes | Yes | |
| `voice:write` | | Yes | Yes | Yes | | Yes |
| `voice:admin` | | | Yes | Yes | | Yes |
| `glossary:read` | | Yes | Yes | Yes | | |
| `glossary:write` | | | Yes | Yes | | Yes |
| `glossary:admin` | | | | Yes | | Yes |

`no_access*` indicates that the rule is **denied** for write/admin/delete actions when `accounts.has_access == false`, even if the relationship check would otherwise allow it.

## Discovery endpoints

Glossia publishes metadata at standard well-known URLs so clients can discover endpoints automatically.

### OAuth Authorization Server Metadata (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Returns the issuer, endpoints, supported scopes, grant types, and code challenge methods.

### Protected Resource Metadata (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Returns the resource identifier, authorization servers, supported scopes, and bearer methods.

## Rate limiting

OAuth endpoints are rate limited per IP address:

| Endpoint | Limit |
|----------|-------|
| `POST /oauth/register` | 5 requests per minute |
| `POST /oauth/token` | 30 requests per minute |
| `POST /oauth/revoke` | 30 requests per minute |
| `POST /oauth/introspect` | 30 requests per minute |

When rate limited, the server returns HTTP 429 (Too Many Requests).
