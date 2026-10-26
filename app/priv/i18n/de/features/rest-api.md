%{
  title: "REST API",
  summary:
    "Eine entwicklerorientierte REST API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und feingranularer Autorisierung. Alles, was Sie im Dashboard tun können, ist über die API möglich.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI dokumentiert",
      description:
        "Eine vollständige OpenAPI 3.1-Spezifikation ermöglicht interaktive Dokumentation über Scalar. Erkunden Sie Endpunkte, führen Sie Anfragen aus und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 mit PKCE",
      description:
        "Dynamische Client-Registrierung, Autorisierungs-Code-Flow mit PKCE, Token-Introspektion und Widerruf. Drittanbieter-Clients authentifizieren sich sicher, ohne Geheimnisse zu teilen.",
      icon: "key-round"
    },
    %{
      title: "Paginierung und Filterung",
      description:
        "Jeder Listen-Endpunkt unterstützt seitenbasierte Paginierung, Feldfilterung und Sortierung von Haus aus. Vorhersehbare Antwortmetadaten machen die Client-Erstellung einfach.",
      icon: "code"
    }
  ]
}
---

## Entwickler zuerst

Die REST-API ist das Rückgrat von Glossia. Das Dashboard, die CLI und der [MCP Server](/features/mcp-server) verbrauchen alle dieselben Endpunkte. Wenn wir eine neue Funktion hinzufügen, landet sie zunächst in der API und wird von dort aus an allen anderen Oberflächen sichtbar.

Dies bedeutet, dass du niemals durch die Benutzeroberfläche eingeschränkt bist. Jeder Workflow, den du dir vorstellen kannst, von CI/CD-Integrationen bis zu benutzerdefinierten Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia verwendet OAuth 2.1 mit PKCE für alle API-Authentifizierungen. Der Ablauf unterstützt sowohl First-Party- als auch Third-Party-Klienten. Siehe die [Authentifizierungs- und Autorisierungs-Dokumentation](/docs/reference/apis/authentication) für die vollständige Anleitung.

**Dynamische Client-Registrierung** -- Klienten registrieren sich programmatisch an `/oauth/register` mit ihren Umleit-URIs und Grant-Typen. Kein manueller Genehmigungsablauf, kein Portal zum Durchklicken.

**Autorisierungscode mit PKCE** -- Benutzer autorisieren Clients über einen browserbasierten Einwilligungsdialog. Der PKCE-Mechanismus gewährleistet, dass Tokens auch bei öffentlichen Clients sicher bleiben, die keinen geheimen Schlüssel speichern können.

**Token-Lebenszyklus** -- Zugriffstokens können ausgetauscht, introspektiert und widerrufen werden. Die Ratenbegrenzung an Token-Endpunkten schützt vor Brute-Force-Attacken.

## Autorisierung

Der Zugriffskontrollmechanismus verwendet zwei Ebenen. Die [Authentifizierungs-Dokumentation](/docs/reference/apis/authentication) behandelt Bereiche, Rollen und die volle Berechtigungs-Matrix im Detail.

**Bereiche** definieren, welche Kategorien von Ressourcen ein Token zugänglich machen kann. Ein Token mit `voice:read` kann Voice-Konfigurationen lesen, diese aber nicht ändern. Bereiche folgen dem `resource:action`-Muster: `account:read`, `organization:write`, `glossary:admin` für die Glossar-Administration und so weiter.

**Richtlinien** prüfen die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Ein gültiges Token mit dem richtigen Bereich kann noch nicht auf eine Organisation zugreifen, der der Benutzer nicht angehört. Jede Anfrage wird gegen beide Ebenen geprüft.

## Paginierung, Filterung und Sortierung

Alle Listen-Endpunkte liefern paginierte Ergebnisse mit konsistenten Metadaten:

Jede Antwort enthält `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` und `has_previous_page?` so dass Klienten Paginierungssteuerelemente aufbauen können, ohne zu raten.

Filtern Sie ein beliebiges indexiertes Feld unter Verwendung von `filters[field]=value`-Abfrageparametern. Sortieren Sie aufsteigend oder absteigend mit `order_by[]`-Parametern. Das Interface ist über jede Ressource identisch.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI 3.1-Spezifikation ist unter `/api/openapi.json`. Die [interaktive API-Referenz](/docs/reference/apis/rest) wird von Scalar angetrieben und ermöglicht es Ihnen, Endpunkte zu erkunden, Schemas zu inspizieren und Testanfragen direkt aus dem Browser zu stellen.

Client-Bibliotheken in jeder Sprache können aus der Spezifikation generiert werden. Der Vertrag ist versioniert und stabil, sodass Ihre Integrationen nicht austreten, wenn wir neue Funktionen bereitstellen.
