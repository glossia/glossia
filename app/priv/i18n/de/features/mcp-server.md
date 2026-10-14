%{
  title: "MCP-Server",
  summary:
    "Verbinden Sie KI-Agenten und Code-Assistenten mit Glossia über das Model Context Protocol. Verwalten Sie Stimmen, Glossare, Organisationen und mehr unter Verwendung einer natürlichen Sprache von jedem MCP-kompatiblen Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürliche Sprachschnittstelle",
      description:
        "Interagieren Sie mit dem Sprachmotor von Glossia durch einfachen Text. KI-Agenten rufen MCP-Tools auf, um Stimmen, Glossare und Organisationen ohne Code zu verwalten.",
      icon: "message-square-text"
    },
    %{
      title: "Verbinden Sie sich mit jedem Agenten",
      description: "Kompatibel mit Claude, Cursor, Windsurf und jedem MCP-kompatiblen Client.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1 Bearer-Tokens authentifiziert und nach feingranulierten Berechtigungen autorisiert. Das gleiche Sicherheitsmodell wie bei der REST API.",
      icon: "shield-check"
    }
  ]
}
---

## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard zur Verbindung von KI-Assistenten mit externen Tools und Datenquellen. Anstatt eigene Integrationen für jeden Code-Assistenten zu erstellen, stellen Sie einen einzigen MCP-Server bereit und jeder kompatible Client kann ihn verwenden.

Der MCP-Server von Glossia gibt Agenten direkten Zugang zum sprachlichen Kern der Plattform: Voice-Konfiguration, Glossarverwaltung, Organisationsverwaltung und Projektliste.

## Verfügbare Tools

Der MCP-Server stellt 16 Tools bereit, die um die Ressourcen herum organisiert sind, mit denen Sie täglich arbeiten. Sehen Sie sich die [vollständige Tool-Referenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails an.

**Konten und Organisationen** -- Listen Sie Ihre Konten auf, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können ganze Teamstrukturen durch Konversation einrichten.

**Voice-Konfiguration** -- Lesen und aktualisieren Sie Voice-Einstellungen, die bestimmen, wie Glossia Inhalte erstellt und überarbeitet. Passen Sie Ton, Formalität, Zielgruppe und pro-locale-Overrides ohne den Editor zu verlassen an.

**Glossarverwaltung** -- Stellen Sie Glossarkonsistenz über alle Ihre Inhalte hinweg sicher. Fügen Sie, aktualisieren Sie und versionieren Sie Glossareinträge, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Listen und untersuchen Sie Projekte über Organisationen hinweg.

## Wie es funktioniert

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` ein und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Der [MCP-Setup-Leitfaden](/docs/reference/mcp/overview) führt den gesamten Verbindungsablauf durch, einschließlich dynamischer Client-Registrierung und PKCE. Der Server verwendet dasselbe Authentifizierungs- und Autorisierungssystem wie das [REST API](/features/rest-api), so dass jedes Token, das für die API funktioniert, auch für MCP funktioniert.

Von dort aus kann Ihr KI-Assistent eines der 16 Tools aufrufen. Fordern Sie ihn an, eine Organisation namens 'Acme' zu erstellen oder meinen Voice-Ton auf 'professionell' zu aktualisieren, und der Agent übersetzt Ihre Intention in den passenden Tool-Aufruf.

## Entwickelt für agentische Workflows

MCP ist nicht nur eine Komfortschicht. Es ist die Grundlage, um Glossia in größere agentische Pipelines einzubinden. Ein Code-Assistent kann Ihre Codebasis lesen, unlokalisierten Inhalt erkennen, das Glossar mit neuen Begriffen aktualisieren, Voice-Einstellungen für ein bestimmtes Locale anpassen und einen Lokalisierungslauf auslösen, alles in einem einzigen Gespräch.

Da das Protokoll standardisiert ist, sind Sie nicht an einen einzelnen Client gebunden. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Konfigurationszeile zu ändern.
