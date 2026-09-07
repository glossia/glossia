%{
  title: "MCP-Server",
  summary:
    "Schließen Sie KI-Agenten und Programmierungsassistenten an Glossia über das Model Context Protocol an. Verwalten Sie Stimmen, Terminologie, Organisationen und mehr mithilfe von natürlicher Sprache von jedem MCP-kompatiblen Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürliche-Sprache-Schnittstelle",
      description:
        "Interagieren Sie mit Glossias linguistischer Engine durch einfachen Text. KI-Agenten rufen MCP-Werkzeuge auf, um Stimmen, Terminologie und Organisationen zu verwalten, ohne Code zu schreiben.",
      icon: "message-square-text"
    },
    %{
      title: "An jeden Agenten anschließen",
      description:
        "Funktioniert mit Claude, Cursor, Windsurf und jedem MCP-kompatiblen Client. Integrieren Sie den Glossia-Server in Ihren bestehenden Agenten-Arbeitsablauf und beginnen Sie sofort damit.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1-Bearer-Token authentifiziert und gemäß feingranularer Berechtigungen autorisiert. Das gleiche Sicherheitsmodell wie die REST API.",
      icon: "shield-check"
    }
  ]
}
---
## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard zum Verbinden von KI-Assistenten mit externen Tools und Datenquellen. Anstatt individuelle Integrationen für jeden Coding-Assistenten zu erstellen, stellen Sie einen einzigen MCP-Server bereit, und jeder kompatible Client kann ihn nutzen.

Der MCP-Server von Glossia bietet Agenten direkten Zugriff auf den sprachlichen Kern der Plattform: Stimmeinstellungen, Terminologieverwaltung, Organsisationsadministration und Projektauflistung.

## Verfügbare Tools

Der MCP-Server stellt 16 Werkzeuge bereit, die um die Ressourcen herum organisiert sind, mit denen Sie täglich arbeiten. Zur Parameterliste und Nutzungsdetails siehe die [vollständige Tool-Referenz](/docs/reference/mcp/tools).

**Konten und Organisationen** -- Listen Sie Ihre Konten auf, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen durch Konversionen einrichten.

**Stimmeinstellungen** -- Lesen und aktualisieren Sie die Stimmenteinstellungen, die steuern, wie Glossia Inhalte generiert und überarbeitet. Passen Sie Sprache, Formalität, Zielgruppe und Locale-Überschreibungen an, ohne Ihren Editor verlassen zu müssen.

**Terminologieverwaltung** -- Stellen Sie die Terminologiekonsistenz in Ihrem gesamten Inhalt sicher. Fügen, update, und versionieren Sie Terminologiepfeile, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Listen und überprüfen Sie Projekte über Organisationen hinweg.

## Funktionsweise

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` aus und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Der [MCP Setup-Guide](/docs/reference/mcp/overview) führt durch den gesamten Verbindungsablauf, einschließlich dynamischer Client-Registrierung und PKCE. Der Server nutzt dasselbe Authentifizierungs- und Autorisierungssystem wie die [REST API](/features/rest-api), sodass jedes Token, das für die API funktioniert, auch für MCP funktioniert.

Von dort aus kann Ihr KI-Assistent eines der 16 Tools aufrufen. Fordern Sie es auf, "eine Organisation namens Acme zu erstellen" oder "meinen Sprachton auf professionell zu aktualisieren", und der Agent übersetzt Ihre Absicht in die richtige Tool-Aufruferfassung.

## Für agentische Workflows optimiert

MCP ist nicht nur eine Conan-Schicht. Es ist die Basis, um Glossia in größere agentische Pipelines zu integrieren. Ein Coding-Assistent kann Ihre Codebasis lesen, unübersetzten Inhalt erkennen, die Terminologie mit neuen Begriffen aktualisieren, die Stimmeinstellungen für ein bestimmtes Locale anpassen und einen Lokalisierungs-Lauf auslösen, alles in einer einzigen Konversation.

Da das Protokoll standardisiert ist, sind Sie keinem einzigen Client gefesselt. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Zeile Konfiguration zu ändern.