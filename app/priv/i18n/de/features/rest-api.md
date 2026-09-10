%{
  title: "REST API",
  summary:
    "Eine für Entwickler gestaltete REST API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feingranularer Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation über Scalar. Entdecken Sie Endpunkte, testen Sie Anfragen und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Autorisierungscode-Flow mit PKCE, Token-Introspektion und Widerruf. Drittanbieter-Clienten authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Jedes Listen-Endpunkt unterstützt Seitenbasierte Paginierung, Feldfilterung und Sortierung standardmäßig. Vorhersehbare Antwortmetadaten machen Client-Entwicklung unkompliziert.",
      icon: "code"
    }
  ]
}
---
## Entwickler zuerst

Die REST-API ist das Rückgrat von Glossia. Das Dashboard, die CLI und die [MCP-Server](/features/mcp-server) alle verbrauchen dieselben Endpunkte. Wenn wir eine Funktion hinzufügen, landet sie zuerst in der API und ist von dort aus überall sonst verfügbar.

Das bedeutet, Sie sind nie durch die UI eingeschränkt. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis zu benutzerdefinierten Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für die gesamte API-Authentifizierung. Der Workflow unterstützt sowohl First-Party- als auch Drittanbieter-Clients. Siehe die [Authentifizierungs- und Autorisierungsdokumentation](/docs/reference/apis/authentication) für die vollständige Anleitung.

**Dynamische Client-Registrierung** -- Clients registrieren sich programmatisch unter `/oauth/register` mit ihren Redirect-URIs und Grant-Typen. Kein manueller Freigabeschritt, kein Portal zum Durchklicken.

**Authorization Code mit PKCE** -- Benutzer autorisieren Clients über einen browserbasierten Einwilligungsbildschirm. Die PKCE-Erweiterung stellt sicher, dass Tokens auch für öffentliche Clients, die kein Geheimnis speichern können, sicher bleiben.

**Token-Lebenszyklus** -- Zugriffstokens können über standardmäßige OAuth-Endpunkte ausgetauscht, abgefragt und widerrufen werden. Die Ratenbegrenzung auf Token-Endpunkten schützt vor Brute-Force-Angriffen.

## Autorisierung

Die Zugriffskontrolle nutzt zwei Ebenen. Die [Authentifizierungsdokumente](/docs/reference/apis/authentication) beschreiben Berechtigungsberieche, Rollen und die vollständige Berechtigungsübersicht im Detail.

**Berechtigungsberieche** definieren, welche Ressourcenkategorien ein Token zugreifen kann. Ein Token mit `voice:read` kann Sprachkonfigurationen lesen, diese aber nicht ändern. Berechtigungsberieche folgen dem `resource:action` Muster: `account:read`, `organization:write`, `glossary:admin` ,für Terminologieverwaltung und so weiter.

**Richtlinien** Prüfen Sie die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit der richtigen Berechtigung gewährt einer Organisation dennoch keinen Zugriff, zu der der Benutzer nicht gehört. Jede Anforderung wird gegen beide Schichten geprüft.

## Paginierung, Filterung und Sortierung

Alle Listenendpunkte geben paginierte Ergebnisse mit konsistenten Metadaten zurück:

Jede Antwort enthält `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, und `has_previous_page?` damit Sie Paginierungssteuerelemente erstellen können, ohne raten zu müssen.

Filtern Sie nach beliebigem indizierten Feld mit `filters[field]=value` Anfrageparametern. Sortieren Sie aufsteigend oder absteigend mit `order_by[]` Parameter. Die Schnittstelle ist über alle Ressourcen hinweg identisch.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation ist verfügbar unter `/api/openapi.json`. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht es Ihnen, Endpunkte zu erkunden, Schemas zu inspizieren und Testanfragen direkt aus dem Browser zu stellen.

Client-Bibliotheken für jede Programmiersprache können aus der Spezifikation generiert werden. Der Vertrag ist versioniert und stabil, sodass Ihre Integrationen nicht beeinträchtigt werden, wenn wir neue Funktionen veröffentlichen.