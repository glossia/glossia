%{
  title: "Configure organization sign-in",
  summary: "Connect Google Workspace or Okta, verify your domain, and manage member permissions.",
  category: "how-to",
  section: "platform",
  edition: "enterprise",
  order: 8
}
---

Connect Google Workspace or Okta so verified work accounts can join your
organization. You need organization administrator access and permission to add
DNS records for your team's email domain.

## 1. Connect your identity provider

Open **Organization → Authentication**, choose a provider, and enter your work
email domain, such as `example.com`.

**Google Workspace:** Glossia manages the Google connection. You do not need to
create an OAuth or SAML application or register a callback address.

**Okta:** Create an [OpenID Connect web application](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/).
Register the redirect address displayed in Glossia, then enter the application's
client ID, client secret, and HTTPS issuer. Glossia supports standard Okta
organization issuers and the `/oauth2/default` authorization server. Secrets are
encrypted at rest; leaving the secret blank when editing preserves its saved value.

Select **Save authentication settings**.

## 2. Verify your domain

At your DNS provider, add the record shown in **Verify domain ownership**:

| Field | Value |
|---|---|
| Type | `TXT` |
| Name / Host | The **Record name** displayed in Glossia, such as `_glossia-verification.example.com` |
| Value / Content | The **Record value** displayed in Glossia, starting with `glossia-domain-verification=` |

If your DNS provider appends the domain automatically, enter only
`_glossia-verification` as the host. Return to Glossia and select **Verify domain**.
If verification fails, check both values and allow time for DNS propagation.
Keep the record in place after verification.

## 3. Test organization sign-in

Ask a team member to enter their work email on the login page and select
**Continue with your organization**. Google Workspace members can also use
**Log in with Google**.

A verified identity with an exact matching email domain automatically joins with
basic read access. Google also requires a valid
[hosted-domain claim](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload);
a personal Google account with the same email suffix does not qualify.
Use [member permissions](/docs/how-to/member-permissions) to grant more access.

To link a new work identity to an **existing Glossia account**, first sign in
with that account's established method, then visit `/auth/login` and start
organization sign-in. Matching an email address alone never links accounts.

## Keep access working

- Glossia rechecks DNS daily. Verification expires 30 days after the last
  successful check; if the record disappears, restore it and verify again before
  that deadline to avoid interrupting sign-in.
- Changing the domain or provider clears verification. Verify again before
  members can use organization sign-in. Changing or disabling the provider also
  removes credentials belonging to the previous provider.
- Disabling sign-in does not delete memberships. Removing a member blocks
  automatic re-enrollment until an administrator explicitly adds or invites them
  again.

Authentication settings, invitations, access credentials, model editing, and
organization deletion remain administrator responsibilities. Administrators can
review configuration changes, domain verification, permission changes, and
successful sign-ins in **Organization → Audit logs**. See [Audit logs](/docs/reference/audit-logs).

SSO uses OpenID Connect, not SAML. It does not provide SCIM provisioning or make
SSO the only login method; existing login methods remain available.

## If Google blocks sign-in

If your organization restricts third-party apps, a Google Workspace administrator
may need to approve Glossia:

1. In the [Google Admin console](https://admin.google.com/), open
   **Security → Access and data control → API controls → Manage third-party app access**.
2. Find Glossia among accessed apps, or use **Configure new app** to search by
   name or OAuth client ID. This is Glossia's shared connection, not an app you
   need to create.
3. Review its permissions, allow the relevant users according to your policy,
   and retry sign-in after the change takes effect.

See Google's [third-party app access guide](https://support.google.com/a/answer/7281227)
for access levels and administrator requirements.
