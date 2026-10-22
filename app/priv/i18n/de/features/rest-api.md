%{
  title: "REST API",
  summary:
    "Eine für Entwickler erstellte REST API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feingranularer Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation über Scalar. Erkunden Sie Endpunkte, testen Sie Anfragen und generieren Sie Client-Code aus einer einzelnen Spezifikationsdatei.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Authorization Code-Flow mit PKCE, Token Introspektion und Widerruf. Externe Clients authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Alle List-Endpunkte unterstützen seitenbasierte Paginierung, Feldfilterung und Sortierung ab Werk. Vorhersagbare Antwort-Metadaten vereinfachen den Client-Aufbau.",
      icon: "code"
    }
  ]
}
---

## ## Entwickler zuerst

Die REST API ist das Rückgrat von Glossia. Das Dashboard, die CLI und der [MCP Server](/features/mcp-server) nutzen alle dieselben Endpunkte. Wenn wir eine neue Funktion hinzufügen, landet sie zuerst in der API und wird von dort aus überall verfügbar gemacht.

Dies bedeutet, dass Sie nie durch die UI eingeschränkt sind. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis hin zu benutzerdefinierten Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für die gesamte API-Authentifizierung. Der Ablauf unterstützt sowohl First-Party- als auch Third-Party-Clients. Sehen Sie sich die [Dokumentation für Authentifizierung und Autorisierung](/docs/reference/apis/authentication) für den vollständigen Walkthrough an.

**Dynamische Client-Registrierung** -- Clients registrieren sich programmatisch bei `/oauth/register` mit ihren Redirect-URIs und Grant-Typen. Kein manueller Freigabeschritt, kein Portal zum Klicken.

**Autorisierungscode mit PKCE** -- Benutzer autorisieren Clients über einen browserbasierten Einwilligungs-Bildschirm. Die PKCE-Erweiterung stellt sicher, dass Tokens auch für Public Clients sicher bleiben, die kein Geheimnis speichern können.

**Token-Lebenszyklus** -- Zugriffstokens können über standardmäßige OAuth-Endpunkte ausgetauscht, introspektiert und widerrufen werden. Die Rate-Limitierung der Token-Endpunkte schützt vor Brute Force.

## Autorisierung

Die Zugriffskontrolle nutzt zwei Ebenen. Die [Authentifizierungsdokumentation](/docs/reference/apis/authentication) behandelt Bereiche, Rollen und die vollständige Berechtigungs-Matrix im Detail.

**Bereiche** definieren, welche Kategorien von Ressourcen ein Token zugreifen kann. Ein Token mit `voice:read` kann Sprach-Konfigurationen lesen, aber nicht ändern. Bereiche folgen dem `resource:action`-Muster: `account:read`, `organization:write`, `glossary:admin` für Glossar-Verwaltung, und so weiter.

**Richtlinien** überprüfen die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit dem richtigen Scope kann dennoch nicht auf eine Organisation zugreifen, der der Benutzer nicht angehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle Listen-Endpunkte liefern paginierte Ergebnisse mit konsistenten Metadaten:

Jede Antwort beinhaltet `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, und `has_previous_page?` so können Clients Paginierungs-Steuerungen ohne zu raten erstellen.

Filtern Sie nach einem beliebigen indexierten Feld unter Verwendung der `filters[field]=value`-Abfrageparameter. Sortieren Sie aufsteigend oder absteigend mit `order_by[]`-Parametern. Die Schnittstelle ist für jede Ressource dieselbe.

## OpenAPI und interaktive Docs

Die vollständige OpenAPI 3.1-Spezifikation ist unter `/api/openapi.json` verfügbar. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht es Ihnen, Endpunkte zu erkunden, Schemas zu prüfen und Testanfragen direkt vom Browser aus zu stellen.

Bibliotheken für Clients in jeder Sprache können aus der Spezifikation generiert werden. Der Vertrag ist versioniert und stabil, sodass Ihre Integrationen nicht brechen, wenn wir neue Funktionen veröffentlichen.
