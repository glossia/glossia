%{
  title: "Login with Glossia",
  summary: "Let users sign in to your app with their Glossia account using OAuth 2.1.",
  category: "how-to",
  order: 2
}
---

This guide walks you through adding "Login with Glossia" to your application. By the end, your users will be able to sign in with their Glossia account and your app will have an access token to call the Glossia API on their behalf.

Glossia uses **OAuth 2.1 with PKCE** (Proof Key for Code Exchange). PKCE is required for all clients, including server-side applications.

## 1. Register your OAuth application

You have two options for registering your application:

### Option A: Through the dashboard (recommended)

1. Sign in to Glossia and go to your account dashboard.
2. Open the **API** section from the sidebar and click **OAuth apps**.
3. Click **New application**.
4. Fill in the application **name** and **callback URL** (also called redirect URI).
5. Click **Create application**.

After creation, note the **Client ID** and **Client secret**. The secret is shown once, so store it securely.

### Option B: Dynamic client registration

Send a `POST` request to `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

The response includes `client_id` and `client_secret`.

## 2. Generate a PKCE code challenge

Before redirecting the user, generate a PKCE code verifier and challenge:

```javascript
function generateCodeVerifier() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function generateCodeChallenge(verifier) {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

const codeVerifier = generateCodeVerifier();
const codeChallenge = await generateCodeChallenge(codeVerifier);
// Store codeVerifier in your session -- you will need it in step 4
```

## 3. Redirect the user to Glossia

Build the authorization URL and redirect the user's browser:

```
https://glossia.ai/oauth/authorize?
  response_type=code
  &client_id=YOUR_CLIENT_ID
  &redirect_uri=https://myapp.com/auth/callback
  &code_challenge=YOUR_CODE_CHALLENGE
  &code_challenge_method=S256
  &scope=user:read+project:read
  &state=RANDOM_STATE_VALUE
```

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `response_type` | Yes | Always `code` |
| `client_id` | Yes | Your application's client ID |
| `redirect_uri` | Yes | Must match a registered callback URL |
| `code_challenge` | Yes | The PKCE code challenge (S256) |
| `code_challenge_method` | Yes | Always `S256` |
| `scope` | No | Space-separated list of [scopes](/docs/reference/apis/authentication). Defaults to minimum access if omitted |
| `state` | Recommended | A random string to prevent CSRF attacks. Verify it matches when the user returns |

The user will see a consent screen showing your application name and the requested scopes. After they approve, Glossia redirects back to your callback URL with an authorization code.

## 4. Exchange the code for tokens

When the user is redirected back to your callback URL, the URL will contain a `code` parameter:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

First, verify that `state` matches what you sent in step 3. Then exchange the code for tokens:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://myapp.com/auth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code_verifier=YOUR_CODE_VERIFIER"
```

The response:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

Store both tokens securely. The access token is used for API requests. The refresh token is used to get a new access token when the current one expires.

## 5. Call the API on behalf of the user

Use the access token to make authenticated API requests:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

The token's scopes limit what endpoints you can access. Resource-level authorization still applies -- for example, a token with `project:read` can only read projects the user has access to.

## 6. Refresh the token

When the access token expires, use the refresh token to get a new one without sending the user through the consent flow again:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Revoke a token

When a user disconnects your app or you no longer need access, revoke the token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Choosing scopes

Request only the scopes your application needs. Here are some common combinations:

| Use case | Scopes |
|----------|--------|
| Read user profile | `user:read` |
| Read projects and content | `user:read project:read voice:read` |
| Manage projects | `user:read project:read project:write` |
| Full organization access | `user:read organization:read organization:write members:read members:write project:read project:write` |

See the [full scopes reference](/docs/reference/apis/authentication) for all available scopes.

## Discovery endpoints

Your application can discover Glossia's OAuth endpoints automatically by fetching the server metadata:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

This returns a JSON document with the `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, and other details. Using discovery makes your integration resilient to endpoint changes.

## Error handling

### Authorization errors

If the user denies consent or something goes wrong during authorization, Glossia redirects to your callback URL with an `error` parameter:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Common error codes:

| Error | Meaning |
|-------|---------|
| `access_denied` | The user denied the authorization request |
| `invalid_request` | The request is missing a required parameter |
| `invalid_scope` | One or more requested scopes are not valid |

### Token errors

The token endpoint returns HTTP 400 with a JSON error body:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Rate limits

OAuth endpoints are rate limited per IP. If you hit the limit, you will receive HTTP 429. See the [rate limiting reference](/docs/reference/apis/authentication) for details.

## Security checklist

Before going to production, verify that your implementation follows these practices:

- Always use HTTPS for callback URLs in production
- Validate the `state` parameter on the callback to prevent CSRF
- Store tokens encrypted at rest
- Never expose tokens in client-side JavaScript or browser URLs
- Use the minimum set of scopes needed
- Handle token expiration gracefully with refresh tokens
- Revoke tokens when users disconnect or delete their account
