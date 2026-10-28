%{
  title: "Single sign-on",
  summary: "Connect your organization's Google Workspace or Okta identity provider with verified-domain enrollment.",
  edition: "enterprise",
  order: 8,
  icon: "key-round",
  hero_cta_text: "Contact us",
  hero_cta_url: "mailto:contact@glossia.ai",
  highlights: [
    %{title: "Your work identity", description: "Use Google Workspace or Okta through OpenID Connect.", icon: "key-round"},
    %{title: "Verified domains", description: "Prove domain ownership with DNS before enabling organization enrollment.", icon: "shield-check"},
    %{title: "Basic access first", description: "New members receive basic permissions; administrators decide which additional access to grant.", icon: "key-round"}
  ]
}
---

## Connect organization access to your identity provider

Enterprise administrators can configure Google Workspace or Okta under
**Enterprise → Authentication**. Members use their work email to start
organization sign-in. Successful identities must have a verified email address
in the exact configured domain.

## Verify ownership before enrollment

DNS verification establishes who controls the domain. Verification lasts 30 days
and is renewed by daily checks while the record remains present. Changing the
domain invalidates verification. Removing a member blocks automatic re-enrollment
until an administrator explicitly restores access.

## Keep existing-account linking safe

An email match alone cannot connect an existing account to a new identity
provider. Existing users authenticate with their established method before
linking a work identity. New members start with basic permissions, and
administrators retain control over elevated access.

## Available in Enterprise

Organization SSO is an Enterprise feature. Ordinary Google, GitHub, and GitLab
login, organizations, invitations, and member permissions remain in Community.
Current support is OpenID Connect, not SAML, SCIM provisioning, or enforced
SSO-only login. Review the [setup guide](/docs/how-to/organization-sign-in) and
[edition comparison](/docs/explanation/editions).
