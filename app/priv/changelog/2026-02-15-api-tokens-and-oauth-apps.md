%{
  title: "Account tokens and OAuth applications",
  summary: "Manage API tokens and register OAuth applications from the dashboard."
}
---

You can now create and manage account tokens and OAuth applications
directly from the API section in your account dashboard.

**Account tokens** let you authenticate with the Glossia API from scripts,
CI pipelines, or any tool that needs programmatic access. Each token can be scoped
to specific permissions and set to expire after 30, 60, or 90 days.

**OAuth applications** let you build integrations that access Glossia on behalf of
users. Register an application to get a client ID and secret, then use the standard
OAuth 2.1 authorization code flow with PKCE to obtain user tokens.

Both features are available to account admins under the new **API** section in the
dashboard sidebar.
