%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Code-Agenten mit Ihren Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt einen [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server, der es Coding-Agenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass jeder MCP-kompatible Client sich authentifizieren kann, ohne manuelle Einrichtung von Anmeldedaten.

## Was der MCP-Server bereitstellt

Sobald eine Verbindung besteht, kann ein Coding-Agent:

- Übersetzungsstatus über Ihre Projekte abfragen
- Übersetzungen und Revisionen auslösen
- Konfigurations- und Inhaltseinträge überprüfen
- Projekt-Kontext für intelligentere Code-Empfehlungen nutzen

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den OAuth 2.1-Autorisierungscode-Flow mit PKCE. Sie müssen OAuth-Clients nicht manuell erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Ihren Server über `/.well-known/oauth-authorization-server`
2. Es registriert sich als OAuth-Client über den dynamischen Registrierungs-Endpunkt.
3. Es öffnet Ihren Browser für die Anmeldung und die Zustimmung.
4. Nach Ihrer Bestätigung empfängt der Agent ein Zugriffstoken und fügt es allen MCP-Anfragen bei.

## Hinzufügen von Glossia zu einem Coding-Agenten

### OpenAI Codex

Fügen Sie den Server in Ihre Codex-Konfigurationsdatei bei `~/.codex/config.toml`:

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

Ersetzen Sie die URL für die lokale Entwicklung:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Fügen Sie den Server zu Ihren Claude Code MCP-Einstellungen hinzu (`.claude/settings.json` oder in der globalen Settingsdatei):

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

Claude Code übernimmt den OAuth-Flow automatisch bei der ersten Verbindung.

### Andere MCP-Clients

Jeder Client, der unterstützt die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funktioniert. Die wichtigsten Anforderungen sind:

- **Transport**: Streaming-HTTP
- **Discovery**: Der Client muss OAuth 2.0 Protected Resource Metadaten ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client-ID-Metadokumente
- **Authentifizierungsablauf**: Autorisierungscode mit PKCE (S256)

Richten Sie den Client auf die URL Ihres Glossia-MCP-Servers aus und lassen Sie ihn die Discovery und Registrierung automatisch übernehmen.

## Discovery-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die von MCP-Clienten verwendet werden, um den OAuth-Flow zu initialisieren:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungs-Servers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Scopes, Autorisierungs-Server) |

## Ratenbegrenzungen

Die OAuth-Endpunkte setzen Ratenbegrenzungen durch, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate Limit überschritten wird, gibt der Server HTTP 429 zurück, mit einem `Retry-After` Header.

## Fehlerbehebung

### Die Registrierung schlägt mit "invalid\_client\_metadata" fehl

Der dynamische Registrierungs-Endpunkt akzeptiert nur bestimmte `token_endpoint_auth_method` Werte. Öffentliche Clients (die meisten Coding-Agenten) sollten senden `"none"`, was Glossia automatisch durch Fallback auf Standardauthentifizierungsmethoden mit PKCE-Enforcement bewältigt.

### "Ungültiger OAuth-Callback" nach der Genehmigung

Stellen Sie sicher, dass Ihr Glossia-Server gestartet ist und über die von Ihnen konfigurierte URL erreichbar ist. Der Callback erfolgt an einem lokalen Port, den der Code-Agent vorübergehend öffnet. Firewalls oder VPNs können dies manchmal blockieren.

### Token-Umtausch schlägt fehl

Überprüfen Sie, ob das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungs-Servers vorhanden ist. Der Server muss S256-Unterstützung signalisieren, damit PKCE funktioniert. Glossia beinhaltet dies standardmäßig.

### Agent kann den Server nicht erreichen

Für die lokale Entwicklung stellen Sie sicher, dass der Phoenix-Server ausgeführt wird (`mix phx.server`) und auf dem erwarteten Port lauscht (Standard: 4050). Der MCP-Endpunkt muss vom Agentenprozess aus erreichbar sein.