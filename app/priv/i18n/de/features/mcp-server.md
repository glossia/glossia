%{
  title: "MCP-Server",
  summary:
    "Verbinden Sie KI-Agenten und Coding-Assistenten mit Glossia über das Model Context Protocol. Verwalten Sie Stimmen, Glossare, Organisationen und mehr mit natürlicher Sprache von jedem MCP-kompatiblen Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürlichsprachige Schnittstelle",
      description:
        "Interagieren Sie mit der Sprachengine von Glossia über einfachen Text. KI-Agenten rufen MCP-Tools auf, um Stimmen, Glossare und Organisationen zu verwalten, ohne Code zu schreiben.",
      icon: "message-square-text"
    },
    %{
      title: "Verknüpfen Sie mit jedem Agenten",
      description:
        "Kompatibel mit Claude, Cursor, Windsurf und jedem MCP-kompatiblen Client. Integrieren Sie den Glossia-Server in Ihren bestehenden Workflow und nutzen Sie ihn sofort.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1-Bearer-Tokens authentifiziert und nach feingranularen Berechtigungen autorisiert. Dasselbe Sicherheitsmodell wie die REST-API.",
      icon: "shield-check"
    }
  ]
}
---

## Was ist MCP?

Das [Modellkontextprotokoll](https://modelcontextprotocol.io) ist ein offener Standard zum Verbinden von KI-Assistenten mit externen Tools und Datenquellen. Anstatt eigene Integrationen für jeden Codingsassistenten zu erstellen, stellen Sie einen einzigen MCP-Server bereit und jeder kompatible Client kann ihn verwenden.

Der MCP-Server von Glossia gewährt Agenten direkten Zugriff auf den sprachlichen Kern der Plattform: Stimmenkonfiguration, Glossarverwaltung, Organisationsverwaltung und Projektliste.

## Verfügbare Werkzeuge

Der MCP-Server stellt 16 Tools bereit, die um Ressourcen herum organisiert sind, mit denen Sie täglich arbeiten. Sehen Sie sich die [Vollständige Tool-Referenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails an.

**Konten und Organisationen** -- Listen Sie Ihre Konten auf, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen durch Konversation einrichten.

**Stimmenkonfiguration** -- Lesen und aktualisieren Sie Stimmeneinstellungen, die steuern, wie Glossia Inhalt generiert und überarbeitet. Passen Sie Tonfall, Formalität, Zielgruppe und pro-locale-Überschreibungen an, ohne Ihren Editor zu verlassen.

**Glossarverwaltung** -- Halten Sie die Glossar-Konsistenz in all Ihrem Inhalt aufrecht. Fügen Sie Glossar-Einträge hinzu, aktualisieren Sie sie und versionieren Sie sie, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Listen Sie Projekte über Organisationen auf und prüfen Sie sie.

## So funktioniert es

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` aus und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Die [MCP-Einrichtungsanleitung](/docs/reference/mcp/overview) führt Sie durch den gesamten Verbindungsablauf, einschließlich der dynamischen Client-Registrierung und PKCE. Der Server verwendet dasselbe Authentifizierungs- und Autorisierungssystem wie die [REST API](/features/rest-api), sodass jeder Token, der für die API funktioniert, auch für MCP funktioniert.

Von dort aus kann Ihr KI-Assistent eines der 16 Werkzeuge aufrufen. Fordern Sie ihn hinzu, "eine Organisation namens Acme zu erstellen" oder "meinen Tonfall auf professionell aktualisieren", und der Agent übersetzt Ihre Absicht in den richtigen Werkzeugaufruf um.

## Ausgelegt für Agenten-Arbeitsabläufe

MCP ist nicht nur eine Komfortschicht. Es ist die Grundlage für das Kombinieren von Glossia in größere Agenten-Arbeitsabläufe. Ein Programmier-Assistent kann Ihren Codebestand lesen, unübersetzten Inhalt erkennen, das Glossar mit neuen Begriffen aktualisieren, Stimmeneinstellungen für eine bestimmte Sprachumgebung anpassen und einen Übersetzungsvorgang auslösen, alles in einer einzigen Konversation.

Da das Protokoll standardisiert ist, sind Sie nicht auf einen einzelnen Client festgelegt. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Zeile Konfiguration zu ändern.
