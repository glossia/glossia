%{
  title: "Protect your account with two-factor authentication",
  summary: "Set up an authenticator, save recovery codes, and require MFA for an organization.",
  category: "how-to",
  section: "platform",
  order: 10
}
---

Personal two-factor authentication is available in **Community and Enterprise**.
Requiring it for organization access is **Enterprise**.

## Enable your authenticator

1. Open **Settings → Security** and select **Set up two-factor authentication**.
2. Sign in again if prompted. Setup and factor changes require authentication
   within the last five minutes.
3. Scan the QR code with 1Password, Google Authenticator, or another TOTP app.
   You can also copy the setup key into your app. Setup expires after five minutes.
4. Enter the six-digit code, keeping any leading zero, and select **Enable
   two-factor authentication**.
5. Save the ten recovery codes in a safe place. They appear only once.

Other browser sessions are signed out when you enable, disable, or regenerate
recovery codes. New browser sign-ins, including Google, GitHub, GitLab and
organization sign-in, must complete MFA before accessing Glossia or approving
CLI/mobile device authorization. A code cannot be used twice.

## Sign in without your authenticator

After your usual sign-in, select **Use a recovery code** and enter an unused
code. Each recovery code works once. After five failed attempts, wait five
minutes before trying again. Starting another sign-in does not reset this limit.

Glossia does not provide an email-only or administrator bypass for a lost factor.
Keep your authenticator or recovery codes available. Support impersonation cannot
access MFA-protected accounts or manage another user's factor.

## Replace recovery codes or disable MFA

Open **Settings → Security**, enter a current authenticator code or unused
recovery code, and select the corresponding action. Generating new recovery
codes invalidates all previous recovery codes. Sign in again if your
authentication is more than five minutes old.

## Require MFA for your organization

An organization administrator with MFA enabled can open **Organization →
Authentication** and select **Enforce MFA** after authenticating within the last
five minutes. Notify members before enabling this policy. **Members** shows each
member's enrollment status.

Unenrolled members are directed to personal security settings rather than removed
from the organization. Existing browser access and subsequent LiveView events
also check the policy. Enrolling restores organization access. Disabling a
personal factor does not disable the organization's policy.

This policy requires **Glossia's own authenticator MFA**, even if your SSO
identity provider also requires MFA. Glossia does not infer MFA assurance from
an OAuth login. Existing API/CLI/MCP bearer credentials and anonymous public
pages are unchanged. An enrolled, recently authenticated administrator can select
**Disable MFA enforcement** to remove the requirement.

## Self-hosted rollout

Run the new core migrations and, for Enterprise, the compiled organization
security migration before starting the new version. Upgrade every
authentication-serving replica before allowing enrollment: older binaries do not
enforce MFA. After enrollment, rollback must use an MFA-compatible version.

No mail, Redis, or external MFA provider is required. Keep server clocks
synchronized and retain the application's stable encryption key and database
backups. TOTP secrets are encrypted, recovery codes and session tokens are hashed,
and challenge responses are not cached. Newly issued browser sessions expire
after eight hours; pending challenges expire after five minutes. Legacy browser
cookies stop working when a user's factor first changes and never become valid
again, even if the factor is later disabled.
