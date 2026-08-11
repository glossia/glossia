%{
  title: "Übersicht",
  summary: "Verbinden Sie Coding-Agents über das Model Context Protocol mit Ihren Glossia-Projekten.",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt einen [Model Context Protocol](https://modelcontextprotocol.io)-(MCP)-Server bereit, der es Coding-Agents ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass sich jeder MCP-kompatible Client ohne manuelle Einrichtung von Anmeldedaten authentifizieren kann.

## Was der MCP-Server bereitstellt

Nach dem Verbindungsaufbau kann ein Coding-Agent:

- Den Übersetzungsstatus über Ihre Projekte hinweg abfragen
- Übersetzungen und Revisionen auslösen
- Konfigurations- und Inhaltseinträge einsehen
- Auf den Projektkontext für intelligentere Code-Vorschläge zugreifen

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den standardmäßigen OAuth 2.1 Authorization Code Flow mit PKCE. Sie müssen OAuth-Clients nicht manuell erstellen. Der Ablauf gestaltet sich wie folgt:

1. Der Agent erkennt Ihren Server über `/.well-known/oauth-authorization-server`.
2. Er registriert sich selbst als OAuth-Client über den Endpunkt für dynamische Registrierung.
3. Er öffnet Ihren Browser für die Anmeldung und Zustimmung.
4. Nach Ihrer Genehmigung erhält der Agent ein Access-Token und fügt dieses allen MCP-Anfragen bei.

## Glossia zu einem Coding-Agenten hinzufügen

### OpenAI Codex

Fügen Sie den Server zu Ihrer Codex-Konfigurationsdatei unter `~/.codex/config.toml` hinzu:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie anschließend den OAuth-Login aus:

```bash
codex mcp login glossia
```

Ihr Browser öffnet sich für die Authentifizierung. Nach der Genehmigung speichert Codex das Token lokal und verwendet es für zukünftige Sitzungen.

So überprüfen Sie die Verbindung:

```bash
codex mcp list
```

Ersetzen Sie für die lokale Entwicklung die URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Fügen Sie den Server zu Ihren Claude Code-MCP-Einstellungen hinzu (`.claude/settings.json` oder zur globalen Einstellungsdatei):

```json
{
  "mcpServers": {
    "glossia": {
      "url": "https://glossia.ai/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Claude Code wickelt den OAuth-Ablauf beim ersten Verbindungsaufbau automatisch ab.

### Andere MCP-Clients

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) unterstützt, ist kompatibel. Die wesentlichen Anforderungen sind:

- **Transport**: Streambares HTTP
- **Erkennung (Discovery)**: Der Client muss OAuth 2.0 Protected Resource Metadata ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728)) unterstützen
- **Registrierung**: Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client ID Metadata Documents
- **Authentifizierungsablauf**: Authorization Code mit PKCE (S256)

Verweisen Sie mit dem Client auf Ihre Glossia-MCP-Server-URL und lassen Sie ihn die Erkennung und Registrierung automatisch abwickeln.

## Erkennungsendpunkte

Der Server veröffentlicht zwei Metadatendokumente, die MCP-Clients für den Einstieg in den OAuth-Ablauf verwenden:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant Types, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Scopes, Autorisierungsserver) |

## Ratenbegrenzungen

Die OAuth-Endpunkte erzwingen Ratenbegrenzungen, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wird eine Ratenbegrenzung überschritten, gibt der Server HTTP 429 mit einem `Retry-After`-Header zurück.

## Fehlerbehebung

### Registrierung schlägt mit „invalid_client_metadata“ fehl

Der Endpunkt für die dynamische Registrierung akzeptiert nur bestimmte Werte für `token_endpoint_auth_method`. Öffentliche Clients (die meisten Coding-Agents) sollten `"none"` senden, was Glossia automatisch verarbeitet, indem auf Standard-Authentifizierungsmethoden mit PKCE-Erzwingung zurückgegriffen wird.

### "Invalid OAuth callback" nach der Genehmigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und unter der von Ihnen konfigurierten URL erreichbar ist. Der Callback erfolgt auf einem lokalen Port, den der Coding-Agent temporär öffnet. Firewalls oder VPNs können dies unter Umständen blockieren.

### Token-Austausch schlägt fehl

Überprüfen Sie, ob das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers vorhanden ist. Der Server muss S256-Unterstützung signalisieren, damit PKCE funktioniert. Glossia enthält dies standardmäßig.

### Agent kann den Server nicht erreichen

Stellen Sie für die lokale Entwicklung sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port lauscht (Standard: 4050). Der MCP-Endpunkt muss vom Agent-Prozess aus erreichbar sein.