%{
  title: "REST API",
  summary:
    "Eine für Entwickler entwickelte REST API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feingranularer Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation über Scalar. Erforschen Sie Endpunkte, testen Sie Anfragen und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Autorisierungscode-Fluss mit PKCE, Token-Inspektion und Widerruf. Drittanbieter-Clients authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Alle Listenendpunkte unterstützen seitenbasierte Paginierung, Feldfilterung und Sortierung standardmäßig. Vorhersehbare Antwortmetadaten erleichtern die Client-Entwicklung.",
      icon: "code"
    }
  ]
}
---
## Entwicklung zuerst

Die REST-API ist das Rückgrat von Glossia. Das Dashboard, die CLI und die [MCP-Server](/features/mcp-server) verwenden alle die gleichen Endpunkte. Wenn wir eine Funktion hinzufügen, landet diese zuerst in der API und von dort aus überall.

Das bedeutet, Sie sind nie durch die Benutzeroberfläche eingeschränkt. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis hin zu individuellen Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia nutzt OAuth 2.1 mit PKCE für alle API-Authentifizierungen. Der Ablauf unterstützt sowohl First-Party- als auch Drittanbieter-Clients. Sehen Sie die [Dokumentation zur Authentifizierung und Autorisierung](/docs/reference/apis/authentication) für den vollständigen Durchlauf.

**Dynamische Client-Registrierung** -- Clients registrieren sich programmatisch unter `/oauth/register` mit ihren Redirect URIs und Grant-Typen. Kein manueller Freigabeschritt, kein Portal zum Klicken.

**Autorisierungscode mit PKCE** -- Benutzer erteilen Clients die Autorisierung über eine browserbasierte Einwilligungsseite. Die PKCE-Erweiterung stellt sicher, dass Tokens auch bei öffentlichen Clients, die keinen geheimen Schlüssel speichern können, sicher bleiben.

**Token-Lebenszyklus** -- Zugriffstokens können über Standard-OAuth-Endpunkte ausgetauscht, introspektiert und widerrufen werden. Die Begrenzung der Anfragefrequenz an Token-Endpunkten schützt vor Brute-Force-Angriffen.

## Autorisierung

Die Zugriffskontrolle verwendet zwei Ebenen. Die [Authentifizierungsdokumente](/docs/reference/apis/authentication) decken Bereiche, Rollen und die vollständige Berechtigungs-Matrix im Detail ab.

**Bereiche** definieren, welche Kategorien von Ressourcen ein Token zugreifen kann. Ein Token mit `voice:read` kann Stimmenkonfigurationen lesen, darf sie aber nicht ändern. Bereiche folgen dem `resource:action` Muster: `account:read`, `organization:write`, `glossary:admin` für Terminologieverwaltung und so weiter.

**Richtlinien** Überprüfen Sie die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit dem richtigen Scope kann dennoch keinen Zugriff auf eine Organisation erhalten, der der Benutzer nicht angehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle Listen-Endpoints geben paginierte Ergebnisse mit konsistenten Metadaten zurück:

Jede Antwort enthält `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, und `has_previous_page?` damit Kunden Paginationssteuerelemente erstellen können, ohne raten zu müssen.

Filtern nach beliebigem indexiertem Feld unter Verwendung von `filters[field]=value` Abfrageparametern. Sortieren aufsteigend oder absteigend mit `order_by[]` Parameter. Die Schnittstelle ist bei jeder Ressource identisch.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation ist verfügbar unter `/api/openapi.json`. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht Ihnen das Erkunden von Endpunkten, das Inspektieren von Schemata und das Stellen von Testanfragen direkt aus dem Browser.

Client-Bibliotheken in jeder Programmiersprache lassen sich aus der Spezifikation generieren. Der Vertrag ist versioniert und stabil, sodass Ihre Integrationen bei der Bereitstellung neuer Funktionen nicht beeinträchtigt werden.