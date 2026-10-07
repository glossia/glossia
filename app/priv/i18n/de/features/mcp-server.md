%{
  title: "MCP-Server",
  summary:
    "Verbinden Sie KI-Agenten und Coding-Assistenten mit Glossia über das Model Context Protocol. Verwalten Sie Stimmen, Glossare, Organisationen und mehr mit natürlicher Sprache von jedem MCP-kompatiblen Client aus.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Natürliche Sprach-Schnittstelle",
      description:
        "Interagieren Sie mit Glossias sprachlicher Engine über einfachen Text. KI-Agenten rufen MCP-Tools auf, um Stimmen, Glossare und Organisationen zu verwalten, ohne Code zu schreiben.",
      icon: "message-square-text"
    },
    %{
      title: "Verbinden Sie mit jedem Agenten",
      description:
        "Unterstützt Claude, Cursor, Windsurf und jeden MCP-kompatiblen Client. Integrieren Sie den Glossia-Server in Ihren bestehenden Agenten-Arbeitsablauf und beginnen Sie sofort damit zu nutzen.",
      icon: "puzzle"
    },
    %{
      title: "Standardmäßig sicher",
      description:
        "Jede MCP-Anfrage wird mit OAuth 2.1-Bearer-Tokens authentifiziert und mit fein granulierten Berechtigungen autorisiert. Das gleiche Sicherheitsmodell wie die REST-API.",
      icon: "shield-check"
    }
  ]
}
---
## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard zur Verbindung von KI-Assistenten mit externen Tools und Datenquellen. Statt für jeden Code-Assistenten eigene Integrationen zu erstellen, stellen Sie einen einzelnen MCP-Server bereit und jeder kompatible Client kann ihn verwenden.

Der MCP-Server von Glossia bietet Agenten direkten Zugriff auf den Sprachkern der Plattform: Sprachkonfiguration, Glossarverwaltung, Organisationsverwaltung und Projektübersicht.

## Verfügbare Tools

Der MCP-Server bietet 16 Tools an, die um die Ressourcen herum organisiert sind, mit denen Sie täglich arbeiten. Sehen Sie die [vollständige Tool-Referenz](/docs/reference/mcp/tools) für Parameter und Nutzungsdetails.

**Konten und Organisationen** -- Verwalten Sie Ihre Konten, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können gesamte Teamstrukturen durch Konversation einrichten.

**Stimmenkonfiguration** -- Lesen und aktualisieren Sie die Stimmeneinstellungen, die steuern, wie Glossia Inhalte erstellt und überarbeitet. Passen Sie Ton, Formalität, Zielgruppe und pro-locale-Überschreibungen an, ohne Ihren Editor zu verlassen.

**Glossarverwaltung** -- Stellen Sie die Glossarkonsistenz in Ihren gesamten Inhalten sicher. Fügen, aktualisieren und versionieren Sie Glossareinträge, damit Agenten immer die richtigen Begriffe verwenden.

**Projekte** -- Auflistung und Prüfung von Projekten über Organisationen hinweg.

## So funktioniert es

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Die [MCP-Einrichtungsanleitung](/docs/reference/mcp/overview) führt Sie durch den vollständigen Verbindungsablauf, einschließlich dynamischer Client-Registrierung und PKCE. Der Server nutzt das gleiche Authentifizierungs- und Autorisierungssystem wie die [REST-API](/features/rest-api)sodass jeder Token, der für die API funktioniert, auch für MCP funktioniert.

Von hier aus kann Ihr KI-Assistent eines der 16 Tools aufrufen. Fordern Sie es auf, "eine Organisation namens Acme zu erstellen" oder "meine Stimmtönung auf professionell einzustellen", und der Agent übersetzt Ihre Absicht in den richtigen Tool-Aufruf.

## Entwickelt für Agenten-Workflows

MCP ist nicht nur eine Komfortschicht. Es ist die Grundlage, Glossia in größere agentische Pipelines einzubetten. Ein Code-Assistent kann Ihre Codebasis durchsuchen, nicht lokalisierten Inhalt erkennen, das Glossar mit neuen Begriffen aktualisieren, Stimmeinstellungen für eine bestimmte Region anpassen und einen Lokalisierungslauf auslösen, alles in einer einzigen Konversation.

Da das Protokoll standardisiert ist, sind Sie nicht an einen einzelnen Client gebunden. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine Konfigurationszeile zu ändern.