%{
  title: "MCP-Server",
  summary:
    "Verbinden Sie KI-Agenten und Coding-Assistenten mit Glossia über das Model Context Protocol. Verwalten Sie Stimmen, Terminologien, Organisationen und mehr mit natürlicher Sprache von jedem kompatiblen MCP-Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürlichsprachige Schnittstelle",
      description:
        "Interagieren Sie mit Glossias linguistischem Motor über einfachen Text. KI-Agenten rufen MCP-Tools auf, um Stimmen, Terminologien und Organisationen zu verwalten, ohne Code zu schreiben.",
      icon: "message-square-text"
    },
    %{
      title: "Schließen Sie sich jedem Agenten an",
      description:
        "Funktioniert mit Claude, Cursor, Windsurf und jedem kompatiblen MCP-Client. Fügen Sie den Glossia-Server in Ihren bestehenden Agenten-Workflow ein und nutzen Sie ihn sofort.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1 Bearer-Tokens authentifiziert und durch feingranulare Scopes autorisiert. Dasselbe Sicherheitsmodell wie die REST-API.",
      icon: "shield-check"
    }
  ]
}
---
## Was ist MCP?

Das [Modell-Kontext-Protokoll](https://modelcontextprotocol.io) ist ein offener Standard zur Verbindung von KI-Assistenten mit externen Tools und Datenquellen. Anstatt benutzerdefinierte Integrationen für jeden Coding-Assistenten zu bauen, stellen Sie einen einzelnen MCP-Server bereit, und jeder kompatible Client kann ihn nutzen.

Glossias MCP-Server ermöglicht Agenten direkten Zugriff auf den sprachlichen Kern der Plattform: Stimmenkonfiguration, Terminologie-Management, Organisationsverwaltung und Projektliste.

## Verfügbare Tools

Der MCP-Server bietet 16 Tools an, die sich um die Ressourcen gruppieren, mit denen Sie täglich arbeiten. Sehen Sie die [vollständige Werkzeugreferenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails.

**Konten und Organisationen** -- Zeigen Sie Ihre Konten an, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen durch Konversation einrichten.

**Stimmenkonfiguration** -- Lesen und aktualisieren Sie die Stimmeinstellungen, die steuern, wie Glossia Inhalte generiert und überarbeitet. Passen Sie Ton, Formalität, Zielgruppe und lokalspezifische Überschreibungen an, ohne Ihren Editor zu verlassen.

**Terminologieverwaltung** -- Stellen Sie Terminologie-Konsistenz in Ihrem gesamten Inhalt sicher. Fügen Sie Terminologie-Einträge hinzu, aktualisieren Sie sie und versionieren Sie sie, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Auflisten und Prüfen von Projekten über Organisationen hinweg.

## So funktioniert es

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Der [MCP-Setup-Anleitung](/docs/reference/mcp/overview) führt Sie durch den gesamten Verbindungsablauf, einschließlich dynamischer Client-Registrierung und PKCE. Der [REST API](/features/rest-api), so funktioniert jedes Token, das für die API funktioniert, auch für MCP.

Von dort aus kann Ihr KI-Assistent eines der 16 Tools aufrufen. Fordern Sie ihn auf, "eine Organisation namens Acme zu erstellen" oder "meinen Stimmton auf professionell zu aktualisieren", und der Agent wandelt Ihre Absicht in den richtigen Tool-Aufruf um.

## Entwickelt für agentische Workflows

MCP ist nicht nur eine Convenience-Schicht. Es ist das Fundament, Glossia in größere agentische Pipelines zu integrieren. Ein Coding-Assistent kann Ihren Codebestand lesen, unlokalisierten Inhalt erkennen, Terminologie mit neuen Begriffen aktualisieren, Stimmeinstellungen für eine bestimmte Zielsprache anpassen und einen Lokalisierungs-Durchlauf auslösen, alles in einer einzigen Konversation.

Da das Protokoll standardisiert ist, sind Sie nicht auf einen einzelnen Client festgelegt. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Zeile der Konfiguration zu ändern.