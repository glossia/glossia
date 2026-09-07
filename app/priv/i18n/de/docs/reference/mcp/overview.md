%{
  title: "Überblick",
  summary: "Verbinde Coding-Agenten mit deinen Glossia-Projekten über Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt ein [Model Context Protocol](https://modelcontextprotocol.io) (MCP) Server, der es Coding-Agenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), so können MCP-kompatible Clients sich authentifizieren, ohne Credentials manuell einzurichten.

## Was der MCP-Server bereitstellt

Sobald verbunden, kann ein Coding-Agent:

- Übersetzungsstatus in Ihren Projekten abfragen
- Übersetzungen und Revisionen auslösen
- Konfiguration und Inhaltseinträge prüfen
- Projekt-Kontext nutzen für intelligentere Codevorschläge

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard-OAuth 2.1-Autorisierungscode-Flow mit PKCE. Sie müssen OAuth-Clienten manuell nicht erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Ihren Server über `/.well-known/oauth-authorization-server`
2. Es registriert sich als OAuth-Client über den dynamischen Registrierungs-Endpoint
3. Es öffnet Ihren Browser für Anmeldung und Einverständnis
4. Nach Ihrer Bestätigung erhält der Agent ein Zugriffstoken und fügt es allen MCP-Anfragen bei

## Hinzufügen von Glossia zu einem Coding-Agenten

### OpenAI Codex

Fügen Sie den Server in die Codex-Konfigurationsdatei ein `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie dann den OAuth-Login aus:

```bash
codex mcp login glossia
```

Ihr Browser öffnet sich zur Authentifizierung. Nach Ihrer Zustimmung speichert Codex das Token lokal und nutzt es für zukünftige Sitzungen.

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

Fügen Sie den Server zu Ihren Claude Code MCP-Einstellungen (`.claude/settings.json` oder der globalen Einstellungsdatei):

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

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funktioniert. Die wichtigsten Anforderungen sind:

- **Transport**: Streambares HTTP
- **Discovery**: Der Client muss OAuth 2.0 Protected Resource Metadata([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client ID Metadatendokumente
- **Authentifizierungsablauf**: Autorisierungscodes mit PKCE (S256)

Leiten Sie den Client auf Ihre Glossia MCP-Server-URL und lassen Sie die Entdeckung und Registrierung automatisch übernehmen.

## Entdeckungsendpunkte

Der Server veröffentlicht zwei Metadatendokumente, die MCP-Clienten nutzen, um den OAuth-Ablauf zu starten:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Bereiche, Autorisierungsserver) |

## Rate limits

Die OAuth-Endpunkte setzen Ratenbegrenzungen durch, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate-Limit überschritten wird, gibt der Server HTTP 429 mit einem `Retry-After` Header.

## Fehlerbehebung

### Die Registrierung schlägt mit \\"invalid\_client\_metadata\\" fehl

Der dynamische Registrierungs-Endpunkt akzeptiert nur bestimmte `token_endpoint_auth_method` Werte. Öffentliche Clients (die meisten Coding-Agenten) sollten senden `"none"`, die Glossia automatisch übernimmt, indem auf Standardauthentifizierungsmethoden mit PKCE-Enforcement zurückgegriffen wird.

### "Ungültiger OAuth-Callback" nach Genehmigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und an der von Ihnen konfigurierten URL erreichbar ist. Der Rückruf erfolgt auf einem lokalen Port, den der Codierungs-Agent vorübergehend öffnet. Firewalls oder VPNs können dies manchmal blockieren.

### Der Tokenaustausch ist fehlgeschlagen

Prüfen Sie, ob das`code_challenge_methods_supported`\`Feld in den Autorisierungsserver-Metadaten enthalten ist. Der Server muss S256-Unterstützung anzeigen, damit PKCE funktioniert. Glossia schließt dies standardmäßig ein.

### Der Agent kann den Server nicht erreichen

Für die lokale Entwicklung, stellen Sie sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port (Standard: 4050) lauscht. Der MCP-Endpunkt muss vom Agenten-Prozess aus erreichbar sein.