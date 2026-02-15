%{
  title: "MCP server",
  summary: "Connect AI agents and coding assistants to Glossia through the Model Context Protocol. Manage voices, glossaries, organizations, and more using natural language from any MCP-compatible client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Get started",
  hero_cta_url: "/interest",
  highlights: [
    %{title: "Natural language interface", description: "Interact with Glossia's linguistic engine through plain text. AI agents call MCP tools to manage voices, glossaries, and organizations without writing code.", icon: "message-square-text"},
    %{title: "Plug into any agent", description: "Works with Claude, Cursor, Windsurf, and any MCP-compatible client. Drop the Glossia server into your existing agentic workflow and start using it immediately.", icon: "puzzle"},
    %{title: "Secure by default", description: "Every MCP request is authenticated with OAuth 2.1 bearer tokens and authorized against fine-grained scopes. The same security model as the REST API.", icon: "shield-check"}
  ]
}
---

## What is MCP?

The [Model Context Protocol](https://modelcontextprotocol.io) is an open standard for connecting AI assistants to external tools and data sources. Instead of building custom integrations for every coding assistant, you expose a single MCP server and any compatible client can use it.

Glossia's MCP server gives agents direct access to the platform's linguistic core: voice configuration, glossary management, organization administration, and project listing.

## Available tools

The MCP server exposes 16 tools organized around the resources you work with daily. See the [full tool reference](/docs/reference/mcp/tools) for parameters and usage details.

**Accounts and organizations** -- List your accounts, create and manage organizations, invite members, and control access. Agents can set up entire team structures through conversation.

**Voice configuration** -- Read and update voice settings that control how Glossia generates and revises content. Adjust tone, formality, target audience, and per-locale overrides without leaving your editor.

**Glossary management** -- Maintain terminology consistency across all your content. Add, update, and version glossary entries so agents always use the right terms.

**Projects** -- List and inspect projects across personal and organization accounts.

## How it works

Point your MCP client at `https://your-glossia-instance/mcp` and authenticate with an OAuth bearer token. The [MCP setup guide](/docs/reference/mcp/overview) walks through the full connection flow, including dynamic client registration and PKCE. The server uses the same authentication and authorization system as the [REST API](/features/rest-api), so any token that works for the API works for MCP.

From there, your AI assistant can call any of the 16 tools. Ask it to "create an organization called Acme" or "update my voice tone to professional" and the agent translates your intent into the right tool call.

## Built for agentic workflows

MCP is not just a convenience layer. It is the foundation for composing Glossia into larger agentic pipelines. A coding assistant can read your codebase, detect untranslated content, update your glossary with new terms, adjust voice settings for a specific locale, and trigger a translation run, all in a single conversation.

Because the protocol is standardized, you are not locked into any single client. Switch between Claude, Cursor, or your own custom agent without changing a line of configuration.
