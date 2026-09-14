%{
  title: "Überblick",
  summary: "Verbinde Code-Agenten mit deinen Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt einen [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server, der es Coding-Agenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass jeder MCP-kompatible Client sich ohne manuelle Einrichtung von Zugangsdaten authentifizieren kann.

## Was der MCP-Server bietet

Sobald verbunden, kann ein Coding-Agent:

- Übersetzungsstatus in Ihren Projekten abfragen
- Übersetzungen und Revisionen auslösen
- Konfiguration und Inhaltseinträge untersuchen
- Projektkontext nutzen für intelligentere Code-Vorschläge

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard OAuth 2.1-Autorisierungscode-Flow mit PKCE. Sie müssen OAuth-Clienten nicht manuell erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Ihren Server über `/.well-known/oauth-authorization-server`
2. Es registriert sich als OAuth-Client über den dynamischen Registrierungs-Endpoint
3. Es öffnet Ihren Browser für Anmeldung und Einwilligung
4. Nach Ihrer Genehmigung erhält der Agent ein Zugriffstoken und fügt es allen MCP-Anfragen hinzu

## Glossia zu einem Coding-Agenten hinzufügen

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

Ihr Browser öffnet sich für die Authentifizierung. Nach der Genehmigung speichert Codex den Token lokal und verwendet ihn für zukünftige Sitzungen.

Um die Verbindung zu überprüfen:

```bash
codex mcp list
```

Für die lokale Entwicklung die URL ersetzen:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Fügen Sie den Server in Ihre Claude Code MCP-Einstellungen ein (`.claude/settings.json` oder in die globale Einstellungsdatei):

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

Claude Code führt den OAuth-Prozess automatisch beim ersten Verbindungsversuch aus.

### Andere MCP-Clients

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) wird funktionieren. Die wichtigsten Voraussetzungen sind:

- **Transport**: Streamfähiger HTTP
- **Entdeckung**: Der Client muss OAuth 2.0 geschützte Ressourcenmetadaten unterstützen ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client-ID-Metadatendokumente
- **Auth-Flow**: Autorisierungscode mit PKCE (S256)

Leiten Sie den Client an Ihre Glossia MCP-Server-URL und lassen Sie Entdeckung und Registrierung automatisch vom Server übernehmen.

## Discovery-Endpunkte

Der Server veröffentlicht zwei Metadatendokumente, die von MCP-Clients genutzt werden, um den OAuth-Flow zu initialisieren:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Bereiche, Autorisierungsserver) |

## Ratenbegrenzungen

Die OAuth-Endpunkte setzen Ratenbegrenzungen durch, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate Limit überschritten wird, gibt der Server HTTP 429 mit einem `Retry-After` Header zurück.

## Fehlerbehebung

### Die Registrierung schlägt mit "invalid\_client\_metadata" fehl

Der dynamische Registrierungsendpunkt akzeptiert nur spezifische `token_endpoint_auth_method` Werte. Öffentliche Clients (meist Code-Agenten) sollten senden, `"none"`"", wobei Glossia dies automatisch übernimmt, indem auf Standardauthentifizierungsmethoden mit PKCE-Enforcement zurückgegriffen wird.

### "Ungültiger OAuth-Callback" nach Genehmigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und unter der von Ihnen konfigurierten URL erreichbar ist. Der Callback erfolgt auf einem lokalen Port, den der Coding-Agent vorübergehend öffnet. Firewalls oder VPNs können dies gelegentlich blockieren.

### Token-Austausch schlägt fehl

Stellen Sie sicher, dass das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers vorhanden ist. Der Server muss S256-Unterstützung angeben, damit PKCE funktioniert. Glossia beinhaltet dies standardmäßig.

### Der Agent kann den Server nicht erreichen

Für die lokale Entwicklung stellen Sie sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port zuhört (Standard: 4050). Der MCP-Endpunkt muss vom Agentenprozess aus erreichbar sein.