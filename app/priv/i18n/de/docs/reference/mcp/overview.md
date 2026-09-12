%{
  title: "Übersicht",
  summary:
    "Verknüpfen Sie Code-Agenten mit Ihren Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt einen [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server, der es Coding-Agenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass jeder MCP-kompatible Client sich ohne manuelle Einrichtung von Anmeldedaten authentifizieren kann.

## Was der MCP-Server bietet

Sobald verbunden, kann ein Coding-Agent:

- Den Übersetzungsstatus für Ihre Projekte abfragen
- Übersetzungen und Revisionen auslösen
- Konfiguration und Inhaltseinträge überprüfen
- Projektkontext für intelligentere Codevorschläge nutzen

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den standardmäßigen OAuth 2.1-Autorisierungscode-Flow mit PKCE. Du musst keine OAuth-Clients manuell erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt deinen Server über `/.well-known/oauth-authorization-server`
2. Es registriert sich als OAuth-Client über den dynamischen Registrierungsendpunkt
3. Es öffnet deinen Browser für Anmeldung und Einwilligung
4. Nach deiner Genehmigung erhält der Agent ein Zugriffstoken und fügt es allen MCP-Anfragen hinzu

## Hinzufügen von Glossia zu einem Coding-Agenten

### OpenAI Codex

Fügen Sie den Server in Ihre Codex-Konfigurationsdatei unter `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie dann den OAuth-Login aus:

```bash
codex mcp login glossia
```

Ihr Browser öffnet sich zur Authentifizierung. Nach der Genehmigung speichert Codex den Token lokal und verwendet ihn für zukünftige Sitzungen.

Um die Verbindung zu überprüfen:

```bash
codex mcp list
```

Für die lokale Entwicklung ersetzen Sie die URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Fügen Sie den Server in Ihre Claude Code MCP-Einstellungen (`.claude/settings.json` oder in der globalen Konfigurationsdatei):

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

Claude Code übernimmt den OAuth-Flow automatisch, wenn es sich erstmals verbindet.

### Andere MCP-Clients

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funktioniert. Die wichtigsten Anforderungen sind:

- **Transport**: Streambares HTTP
- **Entdeckung**: Der Client muss OAuth 2.0 Protected Resource Metadata unterstützen ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client ID-Metadokumente
- **Auth-Flow**: Autorisierungscode mit PKCE (S256)

Leiten Sie den Client an Ihre Glossia MCP-Server-URL und lassen Sie ihn die Entdeckung und Registrierung automatisch übernehmen.

## Discovery-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die MCP-Clients verwenden, um den OAuth-Flow zu initialisieren:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Scopes, Autorisierungsserver) |

## Ratenbegrenzungen

Die OAuth-Endpunkte setzen Ratenbegrenzungen durch, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate-Limit überschritten wird, gibt der Server HTTP 429 zurück, mit einem `Retry-After` Header.

## Fehlerbehebung

### Die Registrierung schlägt mit \\"invalid\_client\_metadata\\" fehl

Der dynamische Registrierungs-Endpunkt akzeptiert nur bestimmte `token_endpoint_auth_method` Werte. Öffentliche Clients (meist Coding-Agenten) sollten senden `"none"`.，die Glossia automatisch verarbeitet, indem auf Standardauthentifizierungsmethoden mit PKCE-Enforcement zurückgegriffen wird.

### "Ungültiger OAuth-Callback" nach der Bestätigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und an der von Ihnen konfigurierten URL erreichbar ist. Der Callback erfolgt an einem lokalen Port, den der Coding-Agent vorübergehend öffnet. Firewalls oder VPNs können dies manchmal blockieren.

### Tokenaustausch schlägt fehl

Stellen Sie sicher, dass das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers vorhanden ist. Der Server muss Unterstützung für S256 bieten, damit PKCE funktioniert. Glossia enthält dies standardmäßig.

### Agent kann den Server nicht erreichen

Für die lokale Entwicklung stellen Sie sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port (Standard: 4050) lauscht. Der MCP-Endpunkt muss vom Agentenprozess aus erreichbar sein.