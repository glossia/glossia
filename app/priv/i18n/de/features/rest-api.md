%{
  title: "REST API",
  summary:
    "Eine für Entwickler erstellte REST API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feingranularer Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API tun.",
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
        "Dynamische Client-Registrierung, Authorization-Code-Flow mit PKCE, Token-Introspektion und Widerruf. Drittanbieter-Clients authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Alle Listen-Endpoints unterstützen standardmäßig seitenbasierte Paginierung, Feldfilterung und Sortierung. Vorhersagbare Antwortmetadaten erleichtern die Erstellung von Clients.",
      icon: "code"
    }
  ]
}
---
## Entwickler zuerst

Die REST API ist das Rückgrat von Glossia. Das Dashboard, die CLI, und der [MCP server](/features/mcp-server) nutzen alle dieselben Endpunkte. Wenn wir eine Funktion hinzufügen, landet sie zuerst in der API und ist von dort aus für alle anderen Stellen verfügbar.

Das bedeutet, Sie sind nie durch die Benutzeroberfläche eingeschränkt. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis hin zu benutzerdefinierten Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für alle API-Authentifizierungen. Der Ablauf unterstützt sowohl First-Party- als auch Third-Party-Clienten. Siehe die [Dokumente zu Authentifizierung und Autorisierung](/docs/reference/apis/authentication) für den vollständigen Durchlauf.

**Dynamische Client-Registrierung** -- Clients registrieren sich programmatisch unter `/oauth/register` mit ihren Redirect URIs und Grant Types. Kein manueller Genehmigungsschritt, kein Portal, durch das geklickt werden muss.

**Autorisierungscode mit PKCE** -- Benutzer autorisieren Clients über ein browserbasiertes Einwilligungsbildschirm. Die PKCE-Extension sorgt dafür, dass Tokens auch für öffentliche Clients sicher bleiben, die kein Geheimnis speichern können.

**Token-Lebenszyklus** -- Zugriffstokens können via Standard-OAuth-Endpunktes ausgetauscht, introspektiert und widerrufen werden. Die Rate Limitierung an den Token-Endpunkten schützt vor Brute-Force-Attacken.

## Autorisierung

Die Zugriffskontrolle nutzt zwei Ebenen. Die [Authentifizierungsdokumente](/docs/reference/apis/authentication) erläutern Scopes, Rollen und die vollständige Berechtigungs-Matrix im Detail.

**Scopes** definieren, welche Ressourcenkategorien ein Token zugreifen kann. Ein Token mit `voice:read` kann Voice-Konfigurationen lesen, darf sie aber nicht ändern. Scopes folgen dem `resource:action`-Muster: `account:read`, `organization:write`, `glossary:admin` für Terminologieverwaltung, und so weiter.

**Policies** überprüfen die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit dem richtigen Scope kann immer noch nicht auf eine Organisation zugreifen, der der Benutzer nicht angehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle List-Endpunkte geben paginierte Ergebnisse mit konsistenten Metadaten zurück:

Jede Antwort enthält `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` und `has_previous_page?`, sodass Clients Paginierungssteuerungen ohne Vermutungen erstellen können.

Filtern Sie nach beliebigen indizierten Feldern mit den Abfrageparametern `filters[field]=value`. Sortieren Sie aufsteigend oder absteigend mit den Parametern `order_by[]`. Die Oberfläche ist bei jeder Ressource identisch.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation ist unter `/api/openapi.json` verfügbar. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht die Erkundung von Endpunkten, den Abusus von Schemata und das Senden von Testanfragen direkt aus dem Browser.

Client-Bibliotheken in beliebigen Programmiersprachen können aus der Spezifikation generiert werden. Der Vertrag ist versioniert und stabil, sodass Ihre Integrationen nicht brechen, wenn wir neue Funktionen veröffentlichen.