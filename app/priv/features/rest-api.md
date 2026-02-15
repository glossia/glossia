%{
  title: "REST API",
  summary: "A developer-first REST API with OpenAPI documentation, OAuth 2.1 authentication, and fine-grained authorization. Everything you can do in the dashboard, you can do through the API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Get started",
  hero_cta_url: "/interest",
  highlights: [
    %{title: "OpenAPI documented", description: "A full OpenAPI 3.1 spec powers interactive documentation via Scalar. Explore endpoints, try requests, and generate client code from a single spec file.", icon: "book-open"},
    %{title: "OAuth 2.1 with PKCE", description: "Dynamic client registration, authorization code flow with PKCE, token introspection, and revocation. Third-party clients authenticate securely without sharing secrets.", icon: "key-round"},
    %{title: "Pagination and filtering", description: "Every list endpoint supports page-based pagination, field filtering, and sorting out of the box. Predictable response metadata makes building clients straightforward.", icon: "code"}
  ]
}
---

## Developer first

The REST API is the backbone of Glossia. The dashboard, the CLI, and the [MCP server](/features/mcp-server) all consume the same endpoints. When we add a feature, it lands in the API first and surfaces everywhere else from there.

This means you are never limited by the UI. Any workflow you can imagine, from CI/CD integrations to custom dashboards, can be built on top of the same stable, documented interface.

## Authentication

Glossia uses OAuth 2.1 with PKCE for all API authentication. The flow supports both first-party and third-party clients. See the [authentication and authorization docs](/docs/reference/apis/authentication) for the full walkthrough.

**Dynamic client registration** -- Clients register programmatically at `/oauth/register` with their redirect URIs and grant types. No manual approval step, no portal to click through.

**Authorization code with PKCE** -- Users authorize clients through a browser-based consent screen. The PKCE extension ensures tokens stay secure even for public clients that cannot store a secret.

**Token lifecycle** -- Access tokens can be exchanged, introspected, and revoked through standard OAuth endpoints. Rate limiting on token endpoints protects against brute force.

## Authorization

Access control uses two layers. The [authentication docs](/docs/reference/apis/authentication) cover scopes, roles, and the full permission matrix in detail.

**Scopes** define what categories of resources a token can access. A token with `voice:read` can read voice configurations but cannot modify them. Scopes follow the `resource:action` pattern: `account:read`, `organization:write`, `glossary:admin`, and so on.

**Policies** verify the relationship between the user and the specific resource. A valid token with the right scope still cannot access an organization the user does not belong to. Every request is checked against both layers.

## Pagination, filtering, and sorting

All list endpoints return paginated results with consistent metadata:

Every response includes `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, and `has_previous_page?` so clients can build pagination controls without guessing.

Filter by any indexed field using `filters[field]=value` query parameters. Sort ascending or descending with `order_by[]` parameters. The interface is the same across every resource.

## OpenAPI and interactive docs

The full OpenAPI 3.1 specification is available at `/api/openapi.json`. The [interactive API reference](/docs/reference/apis/rest) is powered by Scalar and lets you explore endpoints, inspect schemas, and make test requests directly from the browser.

Client libraries in any language can be generated from the spec. The contract is versioned and stable, so your integrations do not break when we ship new features.
