%{
  title: "Organization authentication API",
  summary: "Enterprise REST and MCP interfaces for organization SSO configuration and DNS verification.",
  category: "reference",
  section: "platform",
  edition: "enterprise",
  order: 22
}
---

These interfaces are available in Enterprise. Both an actual organization
administrator and the `organization:admin` credential scope are required,
including for reads. Public organizations do not expose their SSO configuration.

## REST

| Method | Path | Result |
|---|---|---|
| GET | `/api/organizations/:handle/authentication` | Current configuration, DNS record, callback URL, and verification/enforcement status |
| PATCH | `/api/organizations/:handle/authentication` | Partial update; returns the resulting configuration |
| POST | `/api/organizations/:handle/authentication/verify` | Check the configured DNS TXT record; returns configuration on success |

PATCH accepts a JSON object with these fields:

| Field | Type | Meaning |
|---|---|---|
| `auth_provider` | string or null | `google`, `okta`, `oauth2`; empty string or null disables SSO |
| `auth_domain` | string | Exact work email domain |
| `auth_issuer` | string | Okta HTTPS issuer or custom OAuth2 base URL |
| `auth_client_id` | string | Okta/custom OAuth2 client ID |
| `auth_client_secret` | string | Encrypted at rest; omission or empty string preserves the saved value |
| `auth_authorize_url` | string | Custom OAuth2 authorization endpoint |
| `auth_token_url` | string | Custom OAuth2 token endpoint |
| `auth_userinfo_url` | string | Custom OAuth2 user-information endpoint |
| `sso_enforced` | boolean | Set `false` for recovery or before editing an enforced provider |

For `oauth2`, all provider fields are required. Endpoints must be HTTPS on port
443, with no URL credentials, query, or fragment. Token and user-information
requests reject non-public DNS answers and do not follow redirects. The provider
must support authorization code, PKCE S256, Basic client authentication, and
`openid email profile`. User information requires string `sub`, a work `email`,
and boolean `email_verified: true`.

Responses omit `auth_client_secret` entirely. They return
`auth_client_secret_configured`, `domain_verified`, `sso_enforced`, `callback_url`,
and `verification_record` (`name` and `value`, or null), alongside the other
configuration fields. Submitted secrets are not included in validation errors.

Changing provider or domain rotates the verification record and clears verified
ownership. Switching away from custom OAuth2 clears its endpoint settings.
Changing a custom OAuth2 endpoint or client ID requires existing users to relink
their work identity from an authenticated session. Rotating only the client
secret preserves linked identities, but requires a new browser SSO login.

Enabling enforcement requires a successful browser SSO login by the
administrator, through **Organization → Authentication**. REST/MCP cannot provide
that proof: attempting to enable returns `sso_required`. Existing enforcement
can remain enabled in an otherwise unchanged update. Changing an enforced
provider returns `enforcement_enabled`; send `sso_enforced: false` with the edit
to disable and edit atomically. If validation fails, both changes roll back.

Errors use HTTP 401 for missing credentials, 403 for missing scope or membership,
404 for an unknown organization, 422 for validation or failed verification, and
429 for rate limiting. A failed DNS check returns `verification_failed`.

## MCP

| Tool | Arguments |
|---|---|
| `get_organization_authentication` | `handle` |
| `update_organization_authentication` | `handle` plus the PATCH fields above; use an empty provider string to disable |
| `verify_organization_authentication` | `handle` |

All tools use the same authorization, configuration, secret-redaction, and
verification rules as REST. Successful results contain the configuration JSON;
errors describe the rejected operation without including secrets.
