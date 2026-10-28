%{
  title: "Authentication",
  summary: "Browser sign-in, access tokens, and authentication endpoints.",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---

This page describes [Open Authorization](https://oauth.net/2.1/) (OAuth), [Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE), and the [application programming interface](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Protocol specifications linked below are published as Requests for Comments (RFCs).

## Authentication methods

Glossia supports browser sessions and bearer tokens. Bearer tokens can be issued through the authorization flow below or created as [account tokens](/docs/reference/apis/account-tokens).

### Browser sessions

When you sign in through the web interface, Glossia uses session-based authentication. You authenticate via GitHub, GitLab, Google, or a configured organization identity provider using the [Assent](https://github.com/pow-auth/assent) library. After a successful sign-in, a session cookie is set and used for subsequent requests.

Enterprise organizations can configure Google Workspace, Okta, or a custom OAuth2 provider and verify their work email domain before allowing automatic enrollment. See [Configure organization sign-in](/docs/how-to/organization-sign-in) for setup and account-linking requirements, and the [organization authentication API](/docs/reference/organization-authentication) for REST and MCP configuration.

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

Glossia returns `client_id` and `client_secret`. The `localhost` redirect in this example belongs to your application during development. Production applications should register their own secure callback address.

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

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

The response includes an access token and optionally a refresh token.

### 4. Token refresh

When an access token expires, use the refresh token:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

See [Authorization](/docs/reference/apis/authorization) for permission scopes, member access, and resource-level checks.

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

Registration is limited by client address. Token, revocation, and introspection requests are limited by both client address and client identifier:

| Endpoint | Limit |
|----------|-------|
| `POST /oauth/register` | 5 requests per minute |
| `POST /oauth/token` | 30 requests per minute |
| `POST /oauth/revoke` | 30 requests per minute |
| `POST /oauth/introspect` | 30 requests per minute |

When rate limited, the server returns HTTP 429 (Too Many Requests).
