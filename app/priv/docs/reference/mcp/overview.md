%{
  title: "Overview",
  summary: "Connect coding agents to your Glossia projects through the Model Context Protocol.",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---

Glossia exposes a [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server that lets coding agents interact with your localization projects. The server implements OAuth 2.1 with PKCE and Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), so any MCP-compatible client can authenticate without manual credential setup.

## What the MCP server provides

Once connected, a coding agent can list accounts and projects, create projects, manage organization members and invitations, read or update voice and glossary settings, and manage account models and tokens, subject to its permissions.

The server does not currently expose tools to start translations or revisions, or to inspect per-file translation status. See the [tool reference](/docs/reference/mcp) for the available tools.

## Server URL

Connect to Glossia's hosted service at `https://glossia.ai/mcp`. Glossia runs and maintains this endpoint; you only configure the connection in your coding agent.

## Authentication flow

The MCP server uses the standard OAuth 2.1 authorization code flow with PKCE. You do not need to create OAuth clients manually. The flow works like this:

1. The agent discovers Glossia through `https://glossia.ai/.well-known/oauth-authorization-server`
2. It registers itself as an OAuth client via the dynamic registration endpoint
3. It opens your browser for login and consent
4. After you approve, the agent receives an access token and attaches it to all MCP requests

## Adding Glossia to a coding agent

### OpenAI Codex

Following the [Codex connection guide](https://developers.openai.com/codex/mcp), add the server to your Codex configuration file at `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Then run the OAuth login:

```bash
codex mcp login glossia
```

Your browser will open for authentication. After approving, Codex stores the token locally and uses it for future sessions.

To verify the connection:

```bash
codex mcp list
```

### Claude Code

Add the hosted server with the command documented in [Claude Code's connection guide](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Run `/mcp` inside Claude Code and follow the browser authentication flow.

### Other MCP clients

A client must support the [Model Context Protocol authorization flow](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implemented by Glossia. The connection requires:

- **Transport**: Streamable HTTP
- **Discovery**: The client must support OAuth 2.0 Protected Resource Metadata ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registration**: Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Auth flow**: Authorization code with PKCE (S256)

Point the client at `https://glossia.ai/mcp` and let it handle discovery and registration automatically.

## Discovery endpoints

The server publishes two metadata documents that MCP clients use to bootstrap the OAuth flow:

| Endpoint | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Authorization server metadata (endpoints, supported grant types, PKCE methods) |
| `/.well-known/oauth-protected-resource` | Protected resource metadata (scopes, authorization servers) |

## Rate limits

The OAuth endpoints enforce rate limits to prevent abuse:

| Endpoint | Limit |
|---|---|
| `POST /oauth/register` | 5 requests per minute |
| `POST /oauth/token` | 30 requests per minute |
| `POST /oauth/introspect` | 30 requests per minute |
| `POST /oauth/revoke` | 30 requests per minute |

When a rate limit is exceeded, the server returns HTTP 429 with a `Retry-After` header.

## Troubleshooting

### Registration fails with "invalid_client_metadata"

The dynamic registration endpoint only accepts specific `token_endpoint_auth_method` values. Public clients (most coding agents) should send `"none"`, which Glossia handles automatically by falling back to default authentication methods with PKCE enforcement.

### "Invalid OAuth callback" after approving

Confirm that your coding agent can reach `https://glossia.ai`. The callback happens on a local port that the coding agent opens temporarily on your computer. Glossia remains hosted; this local listener belongs to your agent. Firewalls or virtual private networks can sometimes block the callback.

### Token exchange fails

Check that the `code_challenge_methods_supported` field is present in the authorization server metadata. The server must advertise S256 support for PKCE to work. Glossia includes this by default.

### Agent cannot reach the server

Check that the configured endpoint is `https://glossia.ai/mcp` and that your network allows your coding agent to reach it. If the hosted service remains unavailable, contact Glossia support.
