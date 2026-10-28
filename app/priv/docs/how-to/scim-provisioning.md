%{
  title: "Configure SCIM provisioning",
  summary: "Provision organization members and roles from Okta or another SCIM 2.0 identity provider.",
  category: "how-to",
  section: "platform",
  edition: "enterprise",
  order: 9
}
---

SCIM 2.0 lets your identity provider create members, update their provisioning
attributes and organization roles, deactivate access, and reactivate members.
You need organization administrator access. Configure
[organization sign-in](/docs/how-to/organization-sign-in) separately: provisioning
does not authenticate users.

## Generate a provisioning token

1. Open **Organization → Authentication → SCIM provisioning**.
2. Copy the **SCIM endpoint URL**, ending in `/scim/v2`.
3. Enter a token name, such as `Okta`, and select **Generate SCIM token**.
4. Copy the token immediately. Glossia shows it once and stores only its hash.

SCIM tokens belong to the organization and cannot authenticate to the ordinary
REST API or MCP server. Ordinary Glossia API tokens cannot authenticate to SCIM.
To rotate a token, generate a replacement, update the identity provider, test
provisioning, and revoke the old token. Revocation takes effect on subsequent
requests; it does not remove members already provisioned.

## Connect Okta

Use separate Okta applications for OIDC sign-in and SCIM provisioning.

1. Add **SCIM 2.0 Test App (Header Auth)** from Okta's application catalog.
2. Under **Provisioning → Integration**, enable API integration.
3. Set **Base URL** to the SCIM endpoint copied from Glossia.
4. Set **API Token** to `Bearer ` followed by the generated token. This app uses
   the entire field as the Authorization header.
5. Test API credentials and save.
6. Under **Provisioning → To App**, enable **Create Users**, **Update User
   Attributes**, and **Deactivate Users**.
7. Assign a test user. Verify their membership in Glossia, then deactivate and
   reactivate the assignment to check both lifecycle transitions.
8. Assign the same user to the OIDC application if they should sign in with Okta.

## Manage roles with groups

Glossia exposes three fixed groups: **Admins**, **Members**, and **Linguists**.
Map group pushes to these existing groups; arbitrary group creation is not
supported. A user has one organization role, so assigning a different group
replaces their previous role. New members receive basic read access.

Removing an administrator or linguist from their role group returns them to
basic member access. **Members** is the default group and cannot be removed
without deprovisioning. Use user deactivation or `DELETE /Users/:id` to remove
organization membership. Glossia rejects changes that would remove or demote
the last administrator.

## Understand account and identity boundaries

- An unknown email creates a user and their personal account, plus organization
  membership. An existing organization member can be managed without creating
  a duplicate user. Repeating provisioning for the same email is idempotent.
- An email belonging to an existing user outside the organization returns
  `409 uniqueness`. Invite that user first; SCIM cannot claim unrelated accounts.
- Newly SCIM-created accounts can link their first verified organization SSO
  identity at sign-in. Existing accounts still require an authenticated session
  to link a new identity. Provisioning never replaces OAuth credentials.
- `displayName` and `externalId` updates are organization-scoped. `userName`
  identifies the shared user's email and is immutable through SCIM.
- Deactivation removes only this organization's membership and permissions.
  It preserves the user, personal account, other memberships, and work. An
  inactive resource remains addressable so `active: true` can reactivate it.
- Inactive SCIM users cannot regain membership through automatic SSO enrollment.
- Newly attached members receive an email explaining that their identity
  provider added organization access and who to contact if it is unexpected.
  Repeated updates do not resend it; reactivation sends a new notification.
  Delivery is queued transactionally and retried on mail failures, and skips
  access that was revoked before delivery.
- Provisioning-token, membership, and group changes appear in the organization's
  [audit logs](/docs/reference/audit-logs). Tokens are not recorded there.

See the [SCIM API reference](/docs/reference/scim) for supported requests,
attributes, filters, and limits. Test the integration with your provider before
rollout; protocol checks are not certification by Okta or Microsoft Entra.
