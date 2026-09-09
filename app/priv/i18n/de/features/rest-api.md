%{
  title: "REST API",
  summary:
    "Eine REST API für Entwickler mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und granularer Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API erledigen.",
  order: 4,
  icon: "Befehlszeile",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation über Scalar. Erkunden Sie Endpunkte, testen Sie Anfragen und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.",
      icon: "Offenes Buch"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Authorization-Code-Flow mit PKCE, Token-Introspektion und Widerruf. Drittanbieter-Client authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "Schlüssel"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Jeder Listen-Endpunkt unterstützt seitenbasierte Paginierung, Feld-Filterung und Sortierung standardmäßig. Vorhersehbare Antwortmetadaten machen das Erstellen von Clients unkompliziert.",
      icon: "Code"
    }
  ]
}
---
## Entwickler zuerst

Die REST API ist das Rückgrat von Glossia. Das Dashboard, die CLI und der [MCP-Server](/features/mcp-server) alle nutzen dieselben Endpunkte. Wenn wir eine Funktion hinzufügen, landet diese zuerst in der API und steht von dort aus überall zur Verfügung.

Das bedeutet, Sie werden nie durch die Benutzeroberfläche eingeschränkt. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis hin zu benutzerdefinierten Dashboards, kann auf dieser stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für die API-Authentifizierung. Der Ablauf unterstützt sowohl Erst- als auch Drittanbieter-Klenten. Siehe die [Authentifizierungs- und Autorisierungsdokumentation](/docs/reference/apis/authentication) für die vollständige Anleitung.

**Dynamische Clienten-Registrierung** -- Clienten registrieren sich programmatisch unter `/oauth/register` mit ihren Redirect-URIs und Grant-Typen. Kein manueller Genehmigungs-Schritt, kein Portal zum Durchklicken.

**Autorisierungscode mit PKCE** -- Benutzer autorisieren Clienten über einen browserbasierten Einwilligungs-Bildschirm. Die PKCE-Erweiterung stellt sicher, dass Tokens auch für öffentliche Clienten, die kein Geheimnis speichern können, sicher bleiben.

**Token-Lebenszyklus** -- Zugriffstokens können über Standard-OAuth-Endpunkte ausgetauscht, abgefragt und widerrufen werden. Ratenbegrenzung an den Token-Endpunkten schützt vor Brute-Force-Angriffen.

## Autorisierung

Zugriffskontrolle nutzt zwei Ebenen. Die [Authentifizierungsdokumente](/docs/reference/apis/authentication) beschreiben Bereiche, Rollen und die vollständige Berechtigungs-Matrix im Detail.

**Bereiche** definieren, welche Ressourcentypen ein Token zugreifen kann. Ein Token mit `voice:read` kann Stimmen-Konfigurationen lesen, darf sie aber nicht ändern. Bereiche folgen dem `resource:action` Muster: `account:read`Das neu zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textliterals muss ein JSON-String-Array mit gleicher Länge zurückgeben. `organization:write`Das rekonstruierte Dokument hat die Validierung zuvor nicht bestanden: Die Wiederherstellung von Markdown-Text-Literalen muss ein JSON-String-Array mit übereinstimmender Länge zurückgeben `glossary:admin` für Terminologieverwaltung und so weiter.

**Richtlinien** Verifizieren Sie die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit dem richtigen Berechtigungs­bereich kann dennoch nicht auf eine Organisation zugreifen, zu der der Benutzer nicht gehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle Listenendpunkte geben paginierte Ergebnisse mit konsistenten Metadaten zurück:

Jede Antwort enthält `total_count`Das neu zusammengesetzte Dokument hat frühere Validierungsfehler aufgewiesen: Die Wiederherstellung von Markdwntextknoten erzeugte eine leere Übersetzung. `total_pages`Das neu zusammengesetzte Dokument hat die Validierung zuvor nicht bestanden: Die Wiederherstellung von Markdown-Textknoten ergab eine leere Übersetzung. `current_page`Das zuvor rekonstruierte Dokument hat die Validierung nicht bestanden: Die Wiederherstellung der Markdown-Textliteralwerte muss ein JSON-String-Array mit passender Länge zurückgeben. `page_size`, `has_next_page?`, und `has_previous_page?` so Klienten Paginierungssteuerelemente ohne Vermutungen erstellen können.

Filtern Sie nach jedem indexierten Feld unter Verwendung von `filters[field]=value` Abfrageparametern. Sortieren Sie aufsteigend oder absteigend mit `order_by[]` Parameter. Die Schnittstelle ist für jede Ressource identisch.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation steht unter `/api/openapi.json`. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht es, Endpunkte zu erkunden, Schemas zu inspizieren und Testanfragen direkt aus dem Browser zu stellen.

Client-Bibliotheken jeder Sprache können aus der Spezifikation generiert werden. Der Vertrag ist versioniert und stabil, sodass Ihre Integrationen nicht ausfallen, wenn wir neue Funktionen bereitstellen.