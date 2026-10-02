%{
  title: "Configure organization sign-in",
  summary: "Connect Google Workspace or Okta, verify your domain, and manage member permissions.",
  category: "how-to",
  section: "platform",
  order: 8
}
---

## Connect your identity provider

Organization administrators can connect a work identity provider in **Settings → Authentication**.

1. Choose **Google Workspace** or **Okta** and enter the team's work email domain.
2. For Okta, create a web application using [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Enter its issuer, client identifier, and client secret. Glossia supports standard Okta organization issuers and the `/oauth2/default` authorization server. Secrets are encrypted at rest. Leaving the secret blank when editing keeps the saved value.
3. Register the redirect address displayed in Glossia with your identity provider. Google installations also need `/auth/google/callback` for the general **Log in with Google** button.
4. Save the settings. Add the displayed text record through your domain provider, then select **Verify domain**. Changing the email domain creates a new verification token and disables organization sign-in until verified again.
5. Team members enter their work email on the login page and select **Continue with your organization**. Google Workspace members can also use **Log in with Google**.

For Google, the installation operator must set `GLOSSIA_GOOGLE_CLIENT_ID` and `GLOSSIA_GOOGLE_CLIENT_SECRET`. Glossia checks Google's verified email and [hosted-domain claim](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); a personal Google account with the same email suffix does not qualify.

A verified provider identity with an exact matching work email domain automatically joins the organization. For an existing Glossia account connecting Okta for the first time, sign in with the existing method before starting organization sign-in. This safely links the provider without allowing an Okta administrator to take over another Glossia account. Public registration through other providers continues to use the interest form. Disabling the provider stops organization sign-in without deleting existing memberships.

New members receive basic read access to the account, organization, projects, voice, glossary, discussions, and tickets. Follow [Manage member permissions](/docs/how-to/member-permissions) to grant additional access after they join.

## Access safeguards

Domain ownership verification lasts 30 days and is checked automatically every day. Keep the verification record in place. If it disappears, sign-in stops once the last successful verification expires; restore the record and verify again from Authentication settings. Changing providers or disabling organization sign-in clears verification and removes credentials belonging to the previous provider. Unverified claims do not reserve a domain.

For existing accounts, sign in with the existing method first, then visit `/auth/login` and start work email sign-in to connect the work identity. Google can also use an already-linked Google identity with the same provider subject. Matching an email address alone never connects an existing account.

Removing a member blocks automatic re-enrollment. An administrator must explicitly add or invite them again to restore access, even if their work identity is still active.

Member invitation management, access credentials, language model editing, and organization deletion remain administrator responsibilities. These permissions cannot be delegated through member scope checkboxes. Authentication configuration, domain verification, and scope changes emit audit events.
