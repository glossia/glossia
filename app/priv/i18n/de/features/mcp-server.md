%{
  title: "MCP-Server",
  summary:
    "Verbinden Sie KI-Agenten und Coding-Assistenten mit Glossia über das Model Context Protocol. Verwalten Sie Stimmen, Terminologien, Organisationen und vieles mehr mithilfe natürlicher Sprache über jeden MCP-kompatiblen Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürlichsprachige Schnittstelle",
      description:
        "Interagieren Sie mit der linguistischen Engine von Glossia über einfachen Text. KI-Agenten nutzen MCP-Werkzeuge zum Verwalten von Stimmen, Terminologien und Organisationen ohne Programmierung.",
      icon: "message-square-text"
    },
    %{
      title: "Verbinden Sie mit jedem Agenten",
      description:
        "Unterstützt Claude, Cursor, Windsurf und jeden MCP-kompatiblen Client. Ziehen Sie den Glossia-Server in Ihren bestehenden Agenten-Workflow und nutzen Sie ihn sofort.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1 Bearer-Tokens authentifiziert und an feingranulare Berechtigungen autorisiert. Dasselbe Sicherheitsmodell wie die REST API.",
      icon: "shield-check"
    }
  ]
}
---
## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard zur Verbindung von KI-Assistenten mit externen Tools und Datenquellen. Statt für jeden Coding-Assistenten individuelle Integrationen zu erstellen, stellen Sie einen einzelnen MCP-Server bereit, den jeder kompatible Client nutzen kann.

Der MCP-Server von Glossia bietet Agenten direkten Zugriff auf den linguistischen Kern der Plattform: Stimme-Konfiguration, Terminologieverwaltung, Organisationsverwaltung und Projektliste.

## Verfügbare Tools

Der MCP-Server stellt 16 Tools bereit, die nach den Ressourcen organisiert sind, die Sie täglich nutzen. Sehen Sie die [vollständige Tool-Referenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails.

**Konten und Organisationen** -- Ihre Konten auflisten, Organisationen erstellen und verwalten, Mitglieder einladen und Zugriff steuern. Agenten können komplette Teamstrukturen über Konversation einrichten.

**Stimmenkonfiguration** -- Stimmen-Einstellungen einsehen und aktualisieren, die steuern, wie Glossia Inhalte erstellt und überarbeitet. Passen Sie Ton, Formalität, Zielgruppe und Überschreibungen pro Locale an, ohne den Editor zu verlassen.

**Terminologieverwaltung** -- Wahren Sie die Terminologiekonsistenz über alle Inhalte hinweg. Terminologieneinträge hinzufügen, aktualisieren und versionieren, damit Agenten stets die richtigen Begriffe verwenden.

**Projekte** -- Listen und inspizieren Sie Projekte über Organisationen.

## So funktioniert es

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Die [MCP-Einrichtungsanleitung](/docs/reference/mcp/overview) geht den gesamten Verbindungsablauf durch, einschließlich dynamischer Client-Registrierung und PKCE. Die [REST API](/features/rest-api), sodass jeder Token, der für die API funktioniert, auch für MCP funktioniert.

Von dort aus kann Ihr KI-Assistent jedes der 16 Werkzeuge aufrufen. Bitten Sie es, "eine Organisation namens Acme zu erstellen" oder "meinen Stimmenton auf professionell zu aktualisieren", und der Agent übersetzt Ihre Absicht in den passenden Werkzeugaufruf.

## Entwickelt für Agenten-Arbeitsabläufe

MCP ist nicht nur eine Komfortschicht. Es ist das Fundament, um Glossia in größere Agenten-Pipelines zu integrieren. Ein Code-Assistent kann Ihre Codebasis lesen, nicht lokalisierte Inhalte erkennen, die Terminologie mit neuen Begriffen aktualisieren, die Stimmeinstellungen für eine bestimmte Lokalisierung anpassen und einen Lokalisierungsvorgang auslösen, alles in einer einzigen Unterhaltung.

Da das Protokoll standardisiert ist, sind Sie nicht an einen einzelnen Client gebunden. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten ohne eine einzige Konfigurationszeile ändern zu müssen.