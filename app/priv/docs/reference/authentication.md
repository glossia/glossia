%{
  title: "Authentication and authorization",
  summary: "How Glossia authenticates users and authorizes API access.",
  category: "reference",
  order: 3
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
| `org:read` | Read organization details |
| `org:write` | Update organization settings |
| `org:admin` | Manage organization membership and settings |
| `project:read` | Read project configuration |
| `project:write` | Update project settings |
| `project:admin` | Manage project access and settings |
| `project:delete` | Delete a project |
| `translations:read` | Read translations |
| `translations:write` | Create or update translations |
| `translations:admin` | Manage translation settings |
| `glossary:read` | Read glossary entries |
| `glossary:write` | Create or update glossary entries |
| `glossary:admin` | Manage glossary settings |

## Authorization model

Glossia uses a role-based authorization model. Each scope is granted based on the user's relationship to the resource.

### Roles

| Role | Description |
|------|-------------|
| `self` | The user accessing their own resources |
| `org_member` | A member of the organization |
| `org_admin` | An administrator of the organization |
| `account_owner` | The owner of the account that owns the resource |

### Role permissions

| Scope | self | org_member | org_admin | account_owner |
|-------|------|------------|-----------|---------------|
| `user:read` | Yes | Yes | | |
| `user:write` | Yes | | | |
| `org:read` | | Yes | Yes | |
| `org:write` | | | Yes | |
| `org:admin` | | | Yes | |
| `project:read` | | Yes | Yes | Yes |
| `project:write` | | Yes | Yes | Yes |
| `project:admin` | | | Yes | Yes |
| `project:delete` | | | Yes | Yes |
| `translations:read` | | Yes | Yes | Yes |
| `translations:write` | | Yes | Yes | Yes |
| `translations:admin` | | | Yes | Yes |
| `glossary:read` | | Yes | Yes | Yes |
| `glossary:write` | | | Yes | Yes |
| `glossary:admin` | | | | Yes |

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
