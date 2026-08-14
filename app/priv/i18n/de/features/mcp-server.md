%{
  title: "MCP-Server",
  summary: "Verbinden Sie KI-Agenten und Programmierassistenten über das Model Context Protocol mit Glossia. Verwalten Sie Stimmen, Terminologie, Organisationen und mehr in natürlicher Sprache über jeden MCP-kompatiblen Client.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Erste Schritte",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Schnittstelle für natürliche Sprache", description: "Interagieren Sie mittels Klartext mit der linguistischen Engine von Glossia. KI-Agenten rufen MCP-Tools auf, um Stimmen, Terminologie und Organisationen zu verwalten, ohne Code schreiben zu müssen.", icon: "message-square-text"},
    %{title: "Integration in beliebige Agenten", description: "Funktioniert mit Claude, Cursor, Windsurf und jedem MCP-kompatiblen Client. Integrieren Sie den Glossia-Server einfach in Ihren bestehenden agentenbasierten Workflow, um ihn sofort zu nutzen.", icon: "puzzle"},
    %{title: "Standardmäßig sicher", description: "Jede MCP-Anfrage wird mit OAuth-2.1-Bearer-Tokens authentifiziert und anhand feingranularer Scopes autorisiert. Es gilt dasselbe Sicherheitsmodell wie für die REST-API.", icon: "shield-check"}
  ]
}
---
## Was ist MCP?

Das [Model Context Protocol](https://modelcontextprotocol.io) ist ein offener Standard zur Verbindung von KI-Assistenten mit externen Werkzeugen und Datenquellen. Anstatt benutzerdefinierte Integrationen für jeden Programmierassistenten zu entwickeln, stellen Sie einen einzigen MCP-Server bereit, den jeder kompatible Client nutzen kann.

Der MCP-Server von Glossia bietet Agenten direkten Zugriff auf den linguistischen Kern der Plattform: Stimmkonfiguration, Terminologiemanagement, Organisationsverwaltung und Projektauflistung.

## Verfügbare Tools

Der MCP-Server stellt 16 Tools bereit, die nach den Ressourcen strukturiert sind, mit denen Sie täglich arbeiten. Weitere Informationen zu Parametern und zur Verwendung finden Sie in der [vollständigen Tool-Referenz](/docs/reference/mcp/tools).

**Konten und Organisationen** - Listen Sie Ihre Konten auf, erstellen und verwalten Sie Organisationen, laden Sie Mitglieder ein und steuern Sie den Zugriff. Agenten können im Dialog vollständige Teamstrukturen einrichten.

**Stimmkonfiguration** - Lesen und aktualisieren Sie Stimmeinstellungen, die steuern, wie Glossia Inhalte generiert und überarbeitet. Passen Sie Tonfall, Formalität, Zielgruppe und sprachspezifische Überschreibungen an, ohne Ihren Editor zu verlassen.

**Terminologiemanagement** - Gewährleisten Sie eine konsistente Terminologie über all Ihre Inhalte hinweg. Fügen Sie Terminologieeinträge hinzu, aktualisieren und versionieren Sie diese, damit Agenten stets die korrekten Begriffe verwenden.

**Projekte** - Listen und überprüfen Sie Projekte über Organisationen hinweg.

## Funktionsweise

Richten Sie Ihren MCP-Client auf `https://your-glossia-instance/mcp` aus und authentifizieren Sie sich mit einem OAuth-Bearer-Token. Die [MCP-Einrichtungsanleitung](/docs/reference/mcp/overview) führt Sie durch den vollständigen Verbindungsablauf, einschließlich dynamischer Client-Registrierung und PKCE. Der Server nutzt dasselbe Authentifizierungs- und Autorisierungssystem wie die [REST-API](/features/rest-api), sodass jeder Token, der für die API funktioniert, auch für MCP gültig ist.

Von dort aus kann Ihr KI-Assistent jedes der 16 Tools aufrufen. Bitten Sie ihn beispielsweise, „eine Organisation namens Acme zu erstellen“ oder „meinen Stimmtonfall auf professionell zu aktualisieren“, und der Agent übersetzt Ihre Absicht in den passenden Tool-Aufruf.

## Entwickelt für agentenbasierte Workflows

MCP ist nicht nur eine reine Komfortschicht. Es ist das Fundament, um Glossia in größere agentenbasierte Pipelines zu integrieren. Ein Programmierassistent kann Ihre Codebasis analysieren, nicht lokalisierte Inhalte erkennen, die Terminologie um neue Begriffe ergänzen, die Stimmeinstellungen für eine bestimmte Region anpassen und einen Lokalisierungslauf starten, und das alles in einer einzigen Konversation.

Da das Protokoll standardisiert ist, sind Sie an keinen bestimmten Client gebunden. Wechseln Sie zwischen Claude, Cursor oder Ihrem eigenen benutzerdefinierten Agenten, ohne eine einzige Zeile der Konfiguration zu ändern.