%{
  title: "Configure organization sign-in",
  summary: "Connect Google Workspace or Okta, verify your domain, and manage member permissions.",
  category: "how-to",
  section: "platform",
  edition: "enterprise",
  order: 8
}
---

Organization single sign-on (SSO) requires Enterprise. Ordinary Google, GitHub,
and GitLab login, organizations, invitations, and member permissions remain
available in Community. See [Compare editions](/docs/explanation/editions).

## Connect your identity provider

Organization administrators can connect a work identity provider in **Enterprise → Authentication**.

1. Choose **Google Workspace** or **Okta** and enter the team's work email domain.
2. For Okta, create a web application using [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Enter its issuer, client identifier, and client secret. Glossia supports standard Okta organization issuers and the `/oauth2/default` authorization server. Secrets are encrypted at rest. Leaving the secret blank when editing keeps the saved value.
3. For Okta, register the redirect address displayed in Glossia with your identity provider. For Google Workspace, Glossia manages the Google connection; you do not need to create a Google application or register a callback address.
4. Save the settings. Add the displayed DNS TXT record through your domain provider, then select **Verify domain**. Changing the email domain creates a new verification token and disables organization sign-in until verified again.
5. Team members enter their work email on the login page and select **Continue with your organization**. Google Workspace members can also use **Log in with Google**.

## Set up Google Workspace

Glossia manages the Google application credentials. You do not need to create an OAuth application in Google Cloud, add a custom SAML application in Google Admin, or register a redirect address. For an existing Google Workspace domain, setup happens in Glossia and at your DNS provider:

1. In **Enterprise → Authentication**, choose **Google Workspace**, enter your work email domain, and select **Save authentication settings**.
2. Open your domain's DNS settings at the provider that hosts your DNS, not necessarily Google Workspace. Add the record shown in **Verify domain ownership**:

   | Field | Value |
   | --- | --- |
   | Type | `TXT` |
   | Name / Host | The **Record name** displayed in Glossia, such as `_glossia-verification.example.com` |
   | Value / Content | The **Record value** displayed in Glossia, starting with `glossia-domain-verification=` |

   Some DNS providers append your domain automatically. In that case, enter only `_glossia-verification` as the host so the domain is not included twice. Keep the record in place after verification.
3. Return to Glossia and select **Verify domain**. If verification fails, check the name and value and allow time for DNS changes to propagate before trying again.
4. Ask a team member to enter their work email on the login page and select **Continue with your organization**, or use **Log in with Google**.

Glossia checks Google's verified email and [hosted-domain claim](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); a personal Google account with the same email suffix does not qualify.

### If Google blocks sign-in

No Google-side configuration is normally required. If your organization restricts third-party application access, a Google Workspace administrator may need to approve Glossia:

1. Sign in to the [Google Admin console](https://admin.google.com/) with an administrator account.
2. Go to **Security → Access and data control → API controls → Manage third-party app access**.
3. Find Glossia in the list of accessed apps. If it is not listed, use **Configure new app** to search for it by app name or OAuth client ID. The OAuth client ID belongs to Glossia's shared Google connection, not an application you need to create.
4. Review the requested sign-in permissions and allow access for the relevant users according to your organization's policy. See Google's [Control which third-party and internal apps access Google Workspace data](https://support.google.com/a/answer/7281227) guide for access levels and administrator requirements.
5. Retry sign-in with a work account after the policy change takes effect.

## Manage enrollment and permissions

A verified provider identity with an exact matching work email domain automatically joins the organization. For an existing Glossia account connecting Okta for the first time, sign in with the existing method before starting organization sign-in. This safely links the provider without allowing an Okta administrator to take over another Glossia account. Public registration through other providers continues to use the interest form. Disabling the provider stops organization sign-in without deleting existing memberships.

New members receive basic read access to the account, organization, projects, voice, glossary, discussions, and tickets. Follow [Manage member permissions](/docs/how-to/member-permissions) to grant additional access after they join.

## Access safeguards

Domain ownership verification lasts 30 days and is checked automatically every day. Keep the verification record in place. If it disappears, sign-in stops once the last successful verification expires; restore the record and verify again from Authentication settings. Changing providers or disabling organization sign-in clears verification and removes credentials belonging to the previous provider. Unverified claims do not reserve a domain.

For existing accounts, sign in with the existing method first, then visit `/auth/login` and start work email sign-in to connect the work identity. Google can also use an already-linked Google identity with the same provider subject. Matching an email address alone never connects an existing account.

Removing a member blocks automatic re-enrollment. An administrator must explicitly add or invite them again to restore access, even if their work identity is still active.

Member invitation management, access credentials, language model editing, and organization deletion remain administrator responsibilities. These permissions cannot be delegated through member scope checkboxes. Authentication configuration, domain verification, and scope changes emit audit events.

Administrators can review configuration changes and successful organization
sign-ins in **Enterprise → Audit logs**. See the [audit log reference](/docs/reference/audit-logs).
Organization SSO currently uses OpenID Connect, not SAML. It does not include
SCIM provisioning or enforce SSO as the only login method.
