%{
  title: "REST API",
  summary:
    "Eine developer-first REST API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feingranularer Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API tun.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation über Scalar. Erkunden Sie Endpunkte, senden Sie Requests und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Authorization Code Flow mit PKCE, Token-Introspection und Widerruf. Drittanbieter-Clients authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Jeder Listen-Endpunkt unterstützt standardmäßig paginierungsbasierte Paginierung, Feldfilterung und Sortierung. Vorhersehbare Antwortmetadaten machen die Erstellung von Clients einfach.",
      icon: "Code"
    }
  ]
}
---
## Entwickler zuerst

Die REST API ist das Rückgrat von Glossia. Das Dashboard, die CLI und der [MCP-Server](/features/mcp-server) Alle verwenden dieselben Endpunkte. Wenn wir eine Funktion hinzufügen, landet diese zuerst in der API und ist von dort aus überall sichtbar.

Das bedeutet, Sie sind von der UI niemals eingeschränkt. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis hin zu benutzerdefinierten Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für die gesamte API-Authentifizierung. Der Ablauf unterstützt sowohl Erstparte- als auch Drittanbieter-Clienten. Sehen Sie die [Authentifizierungs- und Autorisierungsdokumentation](/docs/reference/apis/authentication) für die vollständige Anleitung.

**Dynamische Clientregistrierung** -- Clients registrieren sich programmatisch bei `/oauth/register` mit ihren Redirect-URIs und Grant-Typen. Kein manueller Genehmigungsschritt, kein Portal zum Durchklicken.

**Autorisierungscode mit PKCE** -- Benutzer autorisieren Clients über einen browserbasierten Einwilligungsdialog. Die PKCE-Erweiterung stellt sicher, dass Token auch für öffentliche Clients sicher bleiben, die kein Geheimnis speichern können.

**Token-Lebenszyklus** -- Access-Tokens können über Standard-OAuth-Endpunkte ausgetauscht, introspektiert und widerrufen werden. Rate Limiting an den Token-Endpunkten schützt vor Brute-Force-Angriffen.

## Autorisierung

Die Zugriffssteuerung nutzt zwei Ebenen. Die [Authentifizierungsdokumente](/docs/reference/apis/authentication) beschreiben Bereiche, Rollen und die vollständige Berechtigungsmatrix im Detail.

**Bereiche** definieren, welche Ressourcenkategorien ein Token zugreifen kann. Ein Token mit `voice:read` kann auf Sprachkonfigurationen lesen, diese aber nicht ändern. Bereiche folgen dem `resource:action` Muster: `account:read`, `organization:write`, `glossary:admin` , für Terminologieverwaltung, und so weiter.

**Richtlinien** Überprüfen Sie die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit den richtigen Berechtigungen kann dennoch keine Organisation zugreifen, der der Benutzer nicht angehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle List-Endpoints liefern paginierte Ergebnisse mit konsistenten Metadaten:

Jede Antwort enthält `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, und `has_previous_page?` damit Kunden Paginierungskontrollen ohne zu raten erstellen können.

Nach jedem indizierten Feld filtern mit `filters[field]=value` Abfrageparameter. Sortieren aufsteigend oder absteigend mit `order_by[]` Parameter. Die Schnittstelle ist bei jeder Ressource identisch,

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation ist verfügbar unter `/api/openapi.json`. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht es Ihnen, Endpunkte zu erkunden, Schemata zu inspizieren und Testanfragen direkt aus dem Browser zu stellen.

Bibliotheken für Clients in jeder beliebigen Programmiersprache können aus der Spezifikation generiert werden. Der Vertrag ist versioniert und stabil, sodass Ihre Integrationen nicht brechen, wenn wir neue Funktionen veröffentlichen.