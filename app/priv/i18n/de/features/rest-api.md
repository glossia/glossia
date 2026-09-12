%{
  title: "REST API",
  summary:
    "Eine developer-first REST API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feingranularer Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API tun.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation über Scalar. Erkunden Sie Endpunkte, testen Sie Anfragen und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Authorization-Code-Flow mit PKCE, Token-Introspektion und Widerruf. Drittanbieter-Clients authentifizieren sich sicher, ohne Geheimnisse teilen zu müssen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Jedes Listen-Endpoint unterstützt Seitenbasierte Paginierung, Feldfilterung und Sortierung von Haus aus. Vorhersehbare Antwortmetadaten erleichtern den Client-Aufbau.",
      icon: "code"
    }
  ]
}
---
## Entwickler zuerst

Die REST API ist das Rückgrat von Glossia. Das Dashboard, die CLI und der [MCP server](/features/mcp-server) nutzen alle dieselben Endpunkte. Wenn wir eine Funktion hinzufügen, landet sie zuerst in der API und steht von dort aus überall zur Verfügung.

Das bedeutet, Sie sind niemals durch die UI eingeschränkt. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis hin zu benutzerdefinierten Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für alle API-Authentifizierungen. Der Flow unterstützt sowohl First-Party- als auch Third-Party-Clients. Siehe die [Dokumentation zu Authentifizierung und Autorisierung](/docs/reference/apis/authentication) für eine vollständige Anleitung.

**Dynamische Client-Registrierung** - Clients registrieren sich programmatisch unter `/oauth/register` mit ihren Umleitungs-URIs und Grant-Typen. Kein manueller Genehmigungs-Schritt, kein Portal zum Durchklicken.

**Autorisierungscode mit PKCE** - Benutzer authorisieren Clients über einen browserbasierten Einwilligungs-Bildschirm. Die PKCE-Erweiterung stellt sicher, dass Tokens auch für öffentliche Clients sicher bleiben, die kein Geheimnis speichern können.

**Token-Lebenszyklus** - Zugangstoken können über Standard-OAuth-Endpunkte ausgetauscht, introspektiert und widerrufen werden. Die Rate Limitierung an den Token-Endpunkten schützt vor Brute-Force-Angriffen.

## Autorisierung

Zugriffskontrolle nutzt zwei Ebenen. Die [Authentifizierungs-Dokumentation](/docs/reference/apis/authentication) geht ausführlich auf Scopes, Rollen und die vollständige Berechtigungsmatrix ein.

**Scopes** legen fest, welche Ressourcentkategorien ein Token zugreifen darf. Ein Token mit `voice:read` kann Stim-Konfigurationen lesen, darf sie aber nicht ändern. Scopes folgen dem `resource:action`-Muster: `account:read`, `organization:write`, `glossary:admin` für Terminologie-Verwaltung und so weiter.

**Policies** überprüfen das Verhältnis zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit dem richtigen Scope kann trotzdem NICHT auf eine Organisation zugreifen, der der Benutzer nicht angehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle Listen-Endpunkte geben paginierte Ergebnisse mit konsistenten Metadaten zurück:

Jede Antwort enthält `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, und `has_previous_page?`, sodass Clients Paginationskontrollen ohne Vermutungen erstellen können.

Filtern Sie nach jedem indizierten Feld mit den Abfrageparametern `filters[field]=value`. Sortieren Sie aufsteigend oder absteigend mit `order_by[]`-Parametern. Die Schnittstelle ist über alle Ressourcen hinweg gleich.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation ist unter `/api/openapi.json` verfügbar. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht es Ihnen, Endpunkte zu erkunden, Schemas zu inspizieren und Testanfragen direkt aus dem Browser auszuführen.

Client-Bibliotheken für jede Sprache können aus der Spezifikation generiert werden. Das Abkommen ist versioniert und stabil, sodass Ihre Integrationen nicht brechen, wenn wir neue Features veröffentlichen.