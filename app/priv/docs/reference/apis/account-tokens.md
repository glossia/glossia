%{
  title: "Account tokens",
  summary: "Create and manage account tokens for authenticating with the Glossia API.",
  category: "reference",
  subcategory: "apis",
  order: 2
}
---

Account tokens provide a simple way to authenticate API requests without going through the full OAuth flow. They are ideal for scripts, CI/CD pipelines, and personal automation.

## Creating a token

1. Sign in to Glossia and navigate to your account dashboard.
2. Open the **API** section from the sidebar.
3. Click **Account tokens**, then **New token**.
4. Give the token a descriptive **name** (for example, "CI deploy" or "CLI access").
5. Choose the **scopes** that the token needs. Only grant the minimum permissions required.
6. Set an **expiration date** or leave it blank for a token that never expires.
7. Click **Create token**.

After creation, the full token value is displayed **once**. Copy it immediately and store it securely. You will not be able to see the full value again.

## Using a token

Include the token in the `Authorization` header of your HTTP requests:

```
Authorization: Bearer glsa_abc123def456...
```

For example, using `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Account tokens follow the same [authorization model](/docs/reference/apis/authentication) as OAuth tokens. The token's scopes define the maximum set of actions it can perform, and resource-level policies still apply based on your account's relationships.

## Token format

All account tokens begin with the `glsa_` prefix followed by a random hex string. This prefix makes it easy to identify Glossia tokens in logs and secret scanners.

## Scopes

Account tokens support the same scopes as OAuth tokens. See the [scopes reference](/docs/reference/apis/authentication) for the full list.

When creating a token, select only the scopes your use case requires. For example:

- A read-only integration needs `project:read` and `voice:read`.
- A CI pipeline that creates projects needs `project:read` and `project:write`.
- A script that manages organization members needs `members:read` and `members:write`.

## Managing tokens

### Viewing tokens

The **Account tokens** page lists all active tokens with their name, scopes, last-used date, and expiration. Tokens that have never been used show "Never" in the last-used column.

### Editing tokens

Click a token's name to edit its **name** and **description**. Scopes and expiration cannot be changed after creation. If you need different scopes, create a new token and revoke the old one.

### Revoking tokens

To revoke a token, click **Revoke** on the token list or open the token's edit page and use the **Revoke token** button in the danger zone. Revoked tokens stop working immediately and cannot be restored.

## Security best practices

- **Store tokens securely.** Use environment variables or a secrets manager. Never commit tokens to source control.
- **Use short-lived tokens.** Set an expiration date whenever possible.
- **Minimize scopes.** Grant only the permissions the token actually needs.
- **Rotate regularly.** Create new tokens and revoke old ones on a schedule.
- **Monitor usage.** Check the "last used" date periodically. Revoke tokens that are no longer in use.
- **Use one token per integration.** This way, revoking one token does not break other workflows.

## API management

You can also manage account tokens through the REST API and MCP server.

### REST API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/tokens` | List active tokens |
| `POST` | `/api/tokens` | Create a new token |
| `DELETE` | `/api/tokens/:id` | Revoke a token |

### MCP

The MCP server exposes `list_tokens`, `create_token`, and `revoke_token` tools that mirror the REST API.
