%{
  title: "REST API",
  summary:
    "Eine für Entwickler konzipierte REST-API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feinkörniger Autorisierung. Alles, was Sie im Dashboard tun können, ist über die API möglich.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation via Scalar. Erkunden Sie Endpunkte, testen Sie Anfragen und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Autorisierungscode-Flow mit PKCE, Token-Introspektion und Widerruf. Drittanbieter-Clients authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Jeder Listen-Endpoint unterstützt standardmäßig die Paginierung, die Filterung von Feldern und die Sortierung. Vorhersagbare Antwortmetadaten erleichtern das Erstellen von Clients.",
      icon: "code"
    }
  ]
}
---
## Entwickler zuerst

Das Dashboard, die CLI und der [MCP-Server](/features/mcp-server) alle dieselben Endpunkte verwenden. Wenn wir eine Funktion hinzufügen, landet sie zuerst in der API und erscheint von dort aus überall sonst.

Das bedeutet, Sie sind nicht auf die Benutzeroberfläche beschränkt. Jeder Workflow, den Sie sich vorstellen können, von CI/CD-Integrationen bis zu benutzerdefinierten Dashboards, lässt sich auf derselben stabilen, dokumentierten Schnittstelle aufbauen.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für die gesamte API-Authentifizierung. Der Authentifizierungsablauf unterstützt sowohl Erstparteien- als auch Drittanbieter-Klienten. Siehe die [Authentifizierungs- und Autorisierungsdokumentation](/docs/reference/apis/authentication) für den vollständigen Durchlauf.

**Dynamische Client-Registrierung** -- Clients registrieren sich programmatisch bei `/oauth/register` mit ihren Redirect URIs und Grant-Typen. Kein manueller Genehmigungsschritt, kein Portal zum Durchklicken.

**Autorisierungscode mit PKCE** -- Benutzer bestätigen Clients über einen browserbasierten Einwilligungsbildschirm. Die PKCE-Erweiterung stellt sicher, dass Tokens auch bei öffentlichen Clients sicher bleiben, die kein Geheimnis speichern können.

**Token-Lebenszyklus** -- Zugriffstokens können über Standard-OAuth-Endpunkte ausgetauscht, geprüft und widerrufen werden. Die Ratenbegrenzung auf Token-Endpunkten schützt vor Brute-Force-Angriffen.

## Autorisierung

Die Zugriffskontrolle nutzt zwei Ebenen. Die [Authentifizierungsdokumentation](/docs/reference/apis/authentication) deckt Bereiche, Rollen und die vollständige Berechtigungs-Matrix im Detail ab.

**Bereiche** definieren, welche Ressourkategorien ein Token zugreifen kann. Ein Token mit `voice:read` kann Stimmkonfigurationen einsehen, kann sie aber nicht ändern. Bereiche folgen dem `resource:action` Muster: `account:read`, `organization:write`, `glossary:admin` für glossary administration, und so weiter.

**Richtlinien** verifizieren Sie die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit dem korrekten Scope kann dennoch keinen Zugriff auf eine Organisation erhalten, der der Benutzer nicht angehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle Listen-Endpunkte geben paginierte Ergebnisse mit konsistenten Metadaten zurück.

Jede Antwort enthält `total_count`, `total_pages`Das neu zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung der Markdown-Textknoten ergab eine leere Übersetzung. `current_page`Das neu zusammengesetzte Dokument hat die Validierung zuvor nicht bestanden: Die Wiederherstellung von Markdown-Textknoten ergab eine leere Übersetzung `page_size`Das zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textknoten ergab eine leere Übersetzung `has_next_page?`, und `has_previous_page?` damit Benutzer Paginierungselemente erstellen können, ohne zu raten.

Filtern nach beliebigem indizierten Feld mit `filters[field]=value` Abfrageparametern. Sortieren aufsteigend oder absteigend mit `order_by[]` Parameter. Die Schnittstelle ist über alle Ressourcen hinweg gleich.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation ist verfügbar unter `/api/openapi.json`. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht es Ihnen, Endpunkte zu erkunden, Schemas zu prüfen und Testanfragen direkt aus dem Browser zu stellen.

Client-Bibliotheken in jeder Sprache können aus der Spezifikation generiert werden. Der Kontrakt ist versioniert und stabile, sodass Ihre Integrationen nicht brechen, wenn wir neue Funktionen bereitstellen.