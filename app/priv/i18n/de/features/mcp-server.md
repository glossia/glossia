%{
  title: "MCP-Server",
  summary:
    "Verbinden Sie KI-Agenten und Programmierassistenten mit Glossia über das Model Context Protocol. Verwalten Sie Stimmen, Terminologie, Organisationen und mehr mittels natürlicher Sprache von jedem MCP-kompatiblen Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürlichsprachliche Schnittstelle",
      description:
        "Interagieren Sie mit der linguistischen Engine von Glossia über einfachen Text. KI-Agenten rufen MCP-Tools auf, um Stimmen, Terminologie und Organisationen zu verwalten, ohne Code zu schreiben.",
      icon: "message-square-text"
    },
    %{
      title: "Schließen Sie sich jedem Agenten an",
      description:
        "Funktioniert mit Claude, Cursor, Windsurf und jedem MCP-kompatiblen Client. Integrieren Sie den Glossia-Server in Ihren bestehenden Agenten-Workflow und nutzen Sie ihn sofort.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1-Bearer-Token authentifiziert und anhand fein granulierter Scopes autorisiert. Das gleiche Sicherheitsmodell wie das REST-API.",
      icon: "shield-check"
    }
  ]
}
---
## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard, um KI-Assistenten mit externen Tools und Datenquellen zu verbinden. Anstatt für jeden Codingsassistenten maßgeschneiderte Integrationen zu erstellen, stellen Sie einen einzigen MCP-Server bereit, der von jedem kompatiblen Client verwendet werden kann.

Der MCP-Server von Glossia gewährt Agenten direkten Zugriff auf das linguistische Kernstück der Plattform: Sprachkonfiguration, Terminologieverwaltung, Organisationsverwaltung und Projektliste.

## Verfügbare Tools

Der MCP-Server bietet 16 Tools an, die sich um die Ressourcen herum organisieren, mit denen Sie täglich arbeiten. Sehen Sie die [vollständige Tool-Referenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails.

**Konten und Organisationen** -- Zeigen Sie Ihre Konten an, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen durch Konversation einrichten.

**Stimme-Konfiguration** -- Zeigen und aktualisieren Sie Stimmenteinstellungen, die steuern, wie Glossia Inhalte generiert und überarbeitet. Passen Sie Ton, Formalität, Zielgruppe und Überschreibungen pro Lokalisierung an, ohne Ihren Editor zu verlassen.

**Terminologie-Verwaltung** -- Bewahren Sie Terminologie-Konsistenz über all Ihren Inhalt auf. Erstellen, aktualisieren und versionieren Sie Terminologie-Einträge, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Projekte über Organisationen auflisten und prüfen.

## So funktioniert es

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Die [MCP-Einrichtungsanleitung](/docs/reference/mcp/overview) führt durch den vollständigen Verbindungsablauf, einschließlich dynamischer Client-Registrierung und PKCE. Der Server verwendet dasselbe Authentifizierungs- und Autorisierungssystem wie die [REST API](/features/rest-api), sodass jedes Token, das für die API funktioniert, auch für MCP funktioniert.

Von hier aus kann Ihr KI-Assistent eines der 16 Tools aufrufen. Fordern Sie es an, "eine Organisation namens Acme zu erstellen" oder "meine Stimme auf professionell einzustellen", und der Agent übersetzt Ihre Absicht in den passenden Tool-Aufruf.

## Entwickelt für agentische Workflows

MCP ist nicht nur eine Komfortschicht. Es ist das Fundament, Glossia in größere agentenbasierte Pipelines zu integrieren. Ein Coding-Assistent kann Ihre Codebasis lesen, nicht lokalisierten Inhalt erkennen, Terminologie mit neuen Begriffen aktualisieren, Stimmeinstellungen für eine bestimmte Sprachregion anpassen und einen Lokalisierungsvorgang auslösen, alles in einer einzigen Konversation.

Da das Protokoll standardisiert ist, sind Sie nicht auf einen einzelnen Client festgelegt. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Zeile der Konfiguration ändern zu müssen.