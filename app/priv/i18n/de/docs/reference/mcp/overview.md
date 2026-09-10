%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Code-Agenten mit Ihren Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt einen [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server, der Codingagenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass jeder MCP-kompatible Client sich authentifizieren kann, ohne manuelle Einrichtung von Anmeldeinformationen.

## Was der MCP-Server bietet

Sobald verbunden, kann ein Codingagent:

- Übersetzungsstatus für Ihre Projekte abfragen
- Übersetzungen und Revisionen auslösen
- Konfiguration und Inhaltseinträge prüfen
- Projektkontext nutzen für intelligentere Code-Vorschläge

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard OAuth 2.1-Autorisierungscode-Fluss mit PKCE. Sie müssen OAuth-Clients manuell nicht erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Ihren Server über `/.well-known/oauth-authorization-server`
2. Es registriert sich als OAuth-Client über den dynamischen Registrierungs-Endpunkt
3. Es öffnet Ihren Browser für Anmeldung und Einwilligung
4. Nach Ihrer Zustimmung erhält der Agent ein Zugriffstoken und befügt es an alle MCP-Anfragen

## Glossia zu einem Coding-Agenten hinzufügen

### OpenAI Codex

Fügen Sie den Server in Ihre Codex-Konfigurationsdatei ein `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie dann die OAuth-Anmeldung aus:

```bash
codex mcp login glossia
```

Ihr Browser öffnet sich zur Authentifizierung. Nach der Genehmigung speichert Codex den Token lokal und verwendet ihn für zukünftige Sitzungen.

Zum Verifizieren der Verbindung:

```bash
codex mcp list
```

Für die lokale Entwicklung ersetzen Sie die URL:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Fügen Sie den Server zu Ihren Claude Code MCP-Einstellungen (`.claude/settings.json` oder der globalen Einstellungen-Datei):

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

Claude Code übernimmt den OAuth-Ablauf automatisch beim ersten Verbinden.

### Andere MCP-Klienten

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) wird funktionieren. Die wichtigsten Anforderungen sind:

- **Transport**: Streamfähiger HTTP
- **Entdeckung**: Der Client muss OAuth 2.0 Protected Resource Metadata unterstützen ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client ID-Metadaten-Dokumente
- **Auth-Ablauf**: Autorisierungscode mit PKCE (S256)

Richten Sie den Client auf Ihre Glossia MCP-Server-URL und lassen Sie die Entdeckung und Registrierung automatisch übernehmen.

## Entdeckungs-Endpunkte

Der Server veröffentlicht zwei Metadaten-Dokumente, die MCP-Clients nutzen, um den OAuth-Ablauf zu starten:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Scopes, Autorisierungsserver) |

## Ratenlimits

Die OAuth-Endpunkte setzen Ratenlimits durch, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Ratenlimit überschritten wird, antwortet der Server HTTP 429 mit einem `Retry-After` Header.

## Fehlerbehebung

### Die Registrierung schlägt fehl mit \\"invalid\_client\_metadata\\"

Der dynamische Registrierungsendpoint akzeptiert nur bestimmte `token_endpoint_auth_method` Werte. Öffentliche Clients (die meisten Coding-Agenten) sollten senden `"none"`, was Glossia automatisch übernimmt, indem es auf Standard-Authentifizierungsmethoden mit PKCE-Durchsetzung zurückfällt.

### "Ungültiger OAuth-Callback" nach der Genehmigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und bei der von Ihnen konfigurierten URL erreichbar ist. Der Callback erfolgt auf einem lokalen Port, den der Code-Agent vorübergehend öffnet. Firewalls oder VPNs können dies gelegentlich blockieren.

### Token-Austausch schlägt fehl

Prüfen Sie, ob das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers vorhanden ist. Der Server muss S256-Unterstützung ausweisen, damit PKCE funktioniert. Dies ist bei Glossia standardmäßig enthalten.

### Agent kann den Server nicht erreichen

Für die lokale Entwicklung stellen Sie sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port (Standard: 4050) lauscht. Der MCP-Endpunkt muss vom Agent-Prozess aus erreichbar sein.