%{
  title: "REST-API",
  summary: "Eine entwicklerorientierte REST-API mit OpenAPI-Dokumentation, OAuth 2.1-Authentifizierung und fein abgestufter Autorisierung. Alles, was Sie im Dashboard tun können, können Sie auch über die API tun.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Jetzt starten",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Über OpenAPI dokumentiert", description: "Eine vollständige OpenAPI 3.1-Spezifikation bildet die Grundlage für die interaktive Dokumentation über Scalar. Erkunden Sie Endpunkte, testen Sie Anfragen und generieren Sie Client-Code aus einer einzigen Spezifikationsdatei.", icon: "book-open"},
    %{title: "OAuth 2.1 mit PKCE", description: "Dynamische Client-Registrierung, Authorization Code Flow mit PKCE, Token-Introspektion und -Widerruf. Drittanbieter-Clients authentifizieren sich sicher, ohne Geheimnisse zu teilen.", icon: "key-round"},
    %{title: "Paginierung und Filterung", description: "Jeder Listen-Endpunkt unterstützt standardmäßig seitenbasierte Paginierung, Feldfilterung und Sortierung. Vorhersehbare Antwort-Metadaten erleichtern die Erstellung von Clients.", icon: "code"}
  ]
}
---
## Entwickler im Fokus

Die REST-API bildet das Rückgrat von Glossia. Das Dashboard, das CLI und der [MCP-Server](/features/mcp-server) nutzen alle dieselben Endpunkte. Wenn wir eine Funktion hinzufügen, wird diese zuerst in der API implementiert und von dort aus überall sonst bereitgestellt.

Das bedeutet, dass Sie niemals durch die Benutzeroberfläche eingeschränkt sind. Jeder denkbare Workflow, von CI/CD-Integrationen bis hin zu benutzerdefinierten Dashboards, kann auf derselben stabilen, dokumentierten Schnittstelle aufgebaut werden.

## Authentifizierung

Glossia nutzt OAuth 2.1 mit PKCE für die gesamte API-Authentifizierung. Der Ablauf unterstützt sowohl First-Party- als auch Third-Party-Clients. Die vollständige Anleitung finden Sie in der [Dokumentation zu Authentifizierung und Autorisierung](/docs/reference/apis/authentication).

**Dynamische Client-Registrierung** - Clients registrieren sich programmatisch unter `/oauth/register` mit ihren Redirect-URIs und Grant-Types. Kein manueller Freigabeschritt, kein Portal, durch das man sich klicken muss.

**Authorization Code mit PKCE** - Benutzer autorisieren Clients über einen browserbasierten Consent-Screen. Die PKCE-Erweiterung stellt sicher, dass Token auch für öffentliche Clients, die kein Secret speichern können, sicher bleiben.

**Token-Lebenszyklus** - Access-Token können über standardmäßige OAuth-Endpunkte ausgetauscht, überprüft (introspected) und widerrufen werden. Eine Ratenbegrenzung (Rate Limiting) an den Token-Endpunkten schützt vor Brute-Force-Angriffen.

## Autorisierung

Die Zugriffskontrolle basiert auf zwei Ebenen. Die [Dokumentation zur Authentifizierung](/docs/reference/apis/authentication) beschreibt Scopes, Rollen und die vollständige Berechtigungsmatrix im Detail.

**Scopes** definieren, auf welche Ressourcenkategorien ein Token zugreifen kann. Ein Token mit `voice:read` kann Konfigurationen der Stimme lesen, diese jedoch nicht ändern. Scopes folgen dem Muster `resource:action`: `account:read`, `organization:write`, `glossary:admin` für die Administration der Terminologie und so weiter.

**Policies** überprüfen die Beziehung zwischen dem Benutzer und der spezifischen Ressource. Selbst ein gültiges Token mit dem passenden Scope kann nicht auf eine Organisation zugreifen, der der Benutzer nicht angehört. Jede Anfrage wird mit beiden Ebenen abgeglichen.

## Paginierung, Filterung und Sortierung

Alle Listen-Endpunkte geben paginierte Ergebnisse mit konsistenten Metadaten zurück:

Jede Antwort enthält `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` und `has_previous_page?`, sodass Clients Steuerelemente für die Paginierung erstellen können, ohne raten zu müssen.

Filtern Sie nach jedem indizierten Feld mithilfe von `filters[field]=value`-Query-Parametern. Sortieren Sie aufsteigend oder absteigend mit `order_by[]`-Parametern. Die Schnittstelle ist bei jeder Ressource identisch.

## OpenAPI und interaktive Dokumentation

Die vollständige OpenAPI-3.1-Spezifikation ist unter `/api/openapi.json` verfügbar. Die [interaktive API-Referenz](/docs/reference/apis/rest) basiert auf Scalar und ermöglicht es Ihnen, Endpunkte zu erkunden, Schemata zu prüfen und Testanfragen direkt aus dem Browser zu senden.

Client-Bibliotheken können in jeder beliebigen Sprache aus der Spezifikation generiert werden. Der API-Vertrag ist versioniert und stabil, sodass Ihre Integrationen bei der Bereitstellung neuer Funktionen nicht beeinträchtigt werden.