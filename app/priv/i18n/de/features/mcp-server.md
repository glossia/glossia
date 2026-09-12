%{
  title: "MCP-Server",
  summary:
    "Verbinden Sie KI-Agenten und Codingsassistenten mit Glossia über das MCP-Protokoll. Verwalten Sie Stimmen, Terminologie, Organisationen und mehr mit natürlicher Sprache von jedem kompatiblen MCP-Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürliche-Sprache-Schnittstelle",
      description:
        "Interagieren Sie mit der linguistischen Engine von Glossia über einfachen Text. KI-Agenten rufen MCP-Tools auf, um Stimmen, Terminologie und Organisationen zu verwalten, ohne Code zu schreiben.",
      icon: "message-square-text"
    },
    %{
      title: "Verbinden Sie sich mit jedem Agenten",
      description:
        "Funktioniert mit Claude, Cursor, Windsurf und jedem kompatiblen MCP-Client. Integrieren Sie den Glossia-Server in Ihren bestehenden agentenbasierten Workflow und beginnen Sie sofort damit.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1-Bearer-Tokens authentifiziert und anhand feingranularer Berechtigungen autorisiert. Dasselbe Sicherheitsmodell wie die REST API.",
      icon: "shield-check"
    }
  ]
}
---
## Was ist MCP?

Das [Modell-Context-Protokoll](https://modelcontextprotocol.io) ist ein offener Standard für die Verbindung von KI-Assistenten mit externen Tools und Datenquellen. Statt dafür eigene Integrationen für jeden Code-Assistenten zu erstellen, stellen Sie einen einzelnen MCP-Server bereit, und jeder kompatible Client kann ihn verwenden.

Der MCP-Server von Glossia gewährt Agenten direkten Zugriff auf den Sprachkern der Plattform: Stimmenkonfiguration, Terminologieverwaltung, Organisationsverwaltung und Projektliste.

## Verfügbare Tools

Der MCP-Server stellt 16 Tools bereit, die nach den Ressourcen organisiert sind, mit denen Sie täglich arbeiten. Sehen Sie die [vollständige Toolreferenz](/docs/reference/mcp/tools) für Parameter und Nutzungsanweisungen.

**Konten und Organisationen** -- Listen Sie Ihre Konten auf, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen durch Konversation einrichten.

**Stimmenkonfiguration** -- Lesen und aktualisieren Sie Stimmeneinstellungen, die steuern, wie Glossia Inhalte erstellt und revidiert. Passen Sie Ton, Formalität, Zielgruppe sowie Lokalisierungsanpassungen an, ohne Ihren Editor verlassen zu müssen.

**Terminologieverwaltung** -- Wahren Sie terminologische Konsistenz über alle Ihre Inhalte. Fügen Sie hinzu, aktualisieren und versionieren Sie Terminologieeinträge, sodass Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Projekte über Organisationen hinweg auflisten und überprüfen.

## Funktionsweise

Verweise deinen MCP-Client auf `https://your-glossia-instance/mcp` und authentifiziere dich mit einem OAuth-Bearer-Token. Der [MCP-Einrichtungsanleitung](/docs/reference/mcp/overview) geht den kompletten Konnektionsablauf durch, inklusive dynamischer Client-Registrierung und PKCE. Der [REST API](/features/rest-api), so funktioniert jedes Token, das für die API funktioniert, auch für MCP.

Von dort aus kann Ihr KI-Assistent jedes der 16 Tools aufrufen. Bitten Sie ihn, "eine Organisation namens Acme zu erstellen" oder "meinen Stimmenton auf professionell zu aktualisieren", und der Agent übersetzt Ihre Absicht in den passenden Tool-Aufruf.

## Für Agenten-Workflows erstellt

MCP ist nicht nur eine Komfortschicht. Es ist die Grundlage, um Glossia in größere Agenten-Pipelines zu integrieren. Ein Code-Assistent kann Ihre Codebasis lesen, nicht lokalisierte Inhalte erkennen, Terminologie mit neuen Begriffen aktualisieren, Stimmeinstellungen für eine bestimmte Sprachumgebung anpassen und einen Lokalisierungslauf auslösen, alles in einer einzigen Unterhaltung.

Da das Protokoll standardisiert ist, sind Sie nicht an einen einzelnen Client gebunden. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Zeile der Konfiguration zu ändern.