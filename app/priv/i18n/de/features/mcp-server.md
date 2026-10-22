%{
  title: "MCP server",
  summary:
    "Connect AI agents and coding assistants to Glossia through the Model Context Protocol. Manage voices, glossary, organizations, and more using natural language from any MCP-compatible client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Get started",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natural language interface",
      description:
        "Interact with Glossia's linguistic engine through plain text. AI agents call MCP tools to manage voices, glossary, and organizations without writing code.",
      icon: "message-square-text"
    },
    %{
      title: "Plug into any agent",
      description:
        "Works with Claude, Cursor, Windsurf, and any MCP-compatible client. Drop the Glossia server into your existing agentic workflow and start using it immediately.",
      icon: "puzzle"
    },
    %{
      title: "Secure by default",
      description:
        "Every MCP request is authenticated with OAuth 2.1 bearer tokens and authorized against fine-grained scopes. The same security model as the REST API.",
      icon: "shield-check"
    }
  ]
}
---

## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard zur Verbindung von KI-Assistenten mit externen Tools und Datenquellen. Anstatt für jeden Codingsassistenten eigene Integrationen zu erstellen, stellen Sie einen einzelnen MCP-Server bereit, und jeder kompatible Client kann ihn verwenden.

Der MCP-Server von Glossia gibt Agenten direkten Zugang zum sprachlichen Kern der Plattform: Stimmmkonfiguration, Glossar-Management, Organisationsverwaltung und Projektliste.

## Verfügbare Tools

Der MCP-Server stellt 16 Tools zur Verfügung, die um die Ressourcen gruppiert sind, mit denen Sie täglich arbeiten. Sehen Sie [die vollst"andige Tool-Referenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails an.

**Konten und Organisationen** -- Listen Sie Ihre Konten, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen durch Konversation einrichten.

**Stimmenkonfiguration** -- Lesen und aktualisieren Sie die Stimmeinstellungen, die steuern, wie Glossia Inhalte erzeugt und revidiert. Passen Sie Ton, Formalität, Zielgruppe und pro-locale-Übergänge an, ohne Ihren Editor zu verlassen.

**Glossar-Management** -- Aufrechterhalten Sie die Glossarkonsistenz über alle Ihre Inhalte. Fügen Sie Glossareinträge ein, aktualisieren Sie sie und versionieren Sie sie, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Listen und untersuchen Sie Projekte über Organisationen.

## So funktioniert es

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` aus und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Die [MCP-Einrichtungsanleitung](/docs/reference/mcp/overview) führt Sie durch den vollständigen Verbindungsablauf, einschließlich dynamischer Client-Registrierung und PKCE. Der Server verwendet dasselbe Authentifizierungs- und Autorisierungssystem wie die [REST-API](/features/rest-api), sodass jedes Token, das für die API funktioniert, auch für MCP funktioniert.

Von da an kann Ihr KI-Assistent eines der 16 Tools aufrufen. Bitten Sie es, "eine Organisation namens Acme zu erstellen" oder "meinen Sprachton professionell anzupassen", und der Agent übersetzt Ihre Absicht in den richtigen Toolaufruf.

## Ausgerichtet auf agentische Workflows

MCP ist nicht nur eine Vereinfachungsschicht. Es ist die Grundlage, Glossia in größere agentische Pipelines zu integrieren. Ein Codingsassistent kann Ihre Codebasis lesen, unlokalisierten Inhalt erkennen, das Glossar mit neuen Begriffen Aktualisieren, Sprachkonfigurationen für eine spezifische Locale anpassen und einen Lokalisierungsprozess auslösen, alles in einem einzigen Gespräch.

Da das Protokoll standardisiert ist, sind Sie nicht an einen einzigen Client gebunden. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Zeile Konfiguration zu ändern.
