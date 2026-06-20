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

Once connected, a coding agent can:

- Query translation status across your projects
- Trigger translations and revisions
- Inspect configuration and content entries
- Access project context for smarter code suggestions

## Server URL

| Environment | URL |
|---|---|
| Production | `https://glossia.ai/mcp` |
| Local development | `http://localhost:4050/mcp` |

## Authentication flow

The MCP server uses the standard OAuth 2.1 authorization code flow with PKCE. You do not need to create OAuth clients manually. The flow works like this:

1. The agent discovers your server through `/.well-known/oauth-authorization-server`
2. It registers itself as an OAuth client via the dynamic registration endpoint
3. It opens your browser for login and consent
4. After you approve, the agent receives an access token and attaches it to all MCP requests

## Adding Glossia to a coding agent

### OpenAI Codex

Add the server to your Codex configuration file at `~/.codex/config.toml`:

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

For local development, replace the URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Add the server to your Claude Code MCP settings (`.claude/settings.json` or the global settings file):

```json
{
  "mcpServers": {
    "glossia": {
      "url": "https://glossia.ai/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Claude Code will handle the OAuth flow automatically when it first connects.

### Other MCP clients

Any client that supports the [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) will work. The key requirements are:

- **Transport**: Streamable HTTP
- **Discovery**: The client must support OAuth 2.0 Protected Resource Metadata ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registration**: Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) or Client ID Metadata Documents
- **Auth flow**: Authorization code with PKCE (S256)

Point the client at your Glossia MCP server URL and let it handle discovery and registration automatically.

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

Make sure your Glossia server is running and reachable at the URL you configured. The callback happens on a local port that the coding agent opens temporarily. Firewalls or VPNs can sometimes block this.

### Token exchange fails

Check that the `code_challenge_methods_supported` field is present in the authorization server metadata. The server must advertise S256 support for PKCE to work. Glossia includes this by default.

### Agent cannot reach the server

For local development, make sure the Phoenix server is running (`mix phx.server`) and listening on the expected port (default: 4050). The MCP endpoint must be accessible from the agent process.
