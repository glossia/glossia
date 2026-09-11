%{
  title: "MCP-Server",
  summary:
    "Schließen Sie KI-Agenten und Programmierassistenten mit Glossia über das Model Context Protocol an. Verwalten Sie Stimmen, Terminologie, Organisationen und mehr mit natürlicher Sprache über jeden MCP-kompatiblen Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Get started",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürliche Sprache-Schnittstelle",
      description:
        "Interagieren Sie mit dem linguistischen Kern von Glossia über einfachen Text. AI-Agenten rufen MCP-Tools auf, um Stimmen, Terminologie und Organisationen zu verwalten, ohne Code zu schreiben.",
      icon: "message-square-text"
    },
    %{
      title: "An jeden Agenten anschließen",
      description:
        "Funktioniert mit Claude, Cursor, Windsurf und jedem MCP-kompatiblen Client. Fügen Sie den Glossia-Server in Ihren bestehenden Agenten-Workflow ein und nutzen Sie ihn sofort.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1-Bearer-Tokens authentifiziert und gegenüber fein granularer Berechtigungen autorisiert. Das gleiche Sicherheitsmodell wie die REST API.",
      icon: "shield-check"
    }
  ]
}
---
## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard, um KI-Assistenten mit externen Tools und Datenquellen zu verbinden. Anstatt benutzerdefinierte Integrationen für jeden Coding-Assistenten zu erstellen, stellst du einen einzelnen MCP-Server bereit, und jeder kompatible Client kann ihn nutzen.

Der Glossia MCP Server bietet Agenten direkten Zugriff auf den linguistischen Kern der Plattform: Sprachkonfiguration, Terminologieverwaltung, Organisationsverwaltung und Projektliste.

## Verfügbare Tools

Der MCP Server stellt 16 Tools bereit, die nach den Ressourcen organisiert sind, mit denen Sie täglich arbeiten. Sehen Sie die [vollständige Tool-Referenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails.

**Konten und Organisationen** -- Verwalten Sie Ihre Konten, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen über Gespräche einrichten.

**Stimmenkonfiguration** -- Anzeigen und aktualisieren Sie die Stimmeinstellungen, die steuern, wie Glossia Inhalte erstellt und überarbeitet werden. Passen Sie Tonfall, Formalität, Zielgruppe und lokalspezifische Überschreibungen an, ohne Ihren Editor zu verlassen.

**Terminologieverwaltung** -- Wahren Sie die Konsistenz der Terminologie in all Ihrem Inhalt. Fügen, aktualisieren und versionieren Sie Terminologieneinträge, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Projekte über Organisationen hinweg auflisten und überprüfen.

## So funktioniert es

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` und authentifizieren Sie sich mit einem OAuth-Bearertoken. Die [MCP-Setupanleitung](/docs/reference/mcp/overview) beschreibt den vollständigen Verbindungsablauf, einschließlich der dynamischen Client-Registrierung und PKCE. Die [REST API](/features/rest-api), sodass jedes Token, das für die API funktioniert, auch für MCP funktioniert.

Von da an kann Ihr KI-Assistent alle 16 Tools aufrufen. Sagen Sie ihm, "eine Organisation namens Acme" zu erstellen oder "meine Stimmlage auf professionell zu aktualisieren", und der Agent übersetzt Ihre Absicht in den richtigen Tool-Aufruf.

## Entwickelt für Agenten-Arbeitsabläufe

MCP ist nicht nur eine Komfortschicht. Es ist die Grundlage, Glossia in größere Agenten-Pipelines zu integrieren. Ein Coding-Assistent kann Ihre Codebasis lesen, unlokalisierten Inhalt erkennen, die Terminologie mit neuen Begriffen aktualisieren, die Stimmeinstellungen für ein spezifisches Sprachumfeld anpassen und einen Lokalisierungsablauf auslösen. Alles in einer einzigen Konversation.

Da das Protokoll standardisiert ist, sind Sie nicht auf einen einzelnen Client gebunden. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine einzige Konfigurationszeile zu ändern.