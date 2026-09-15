%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Coding-Agenten mit Ihren Glossia-Projekten über das Modell-Kontext-Protokoll.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt einen [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server, der es Coding-Agenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), damit jeder MCP-kompatible Client sich ohne manuelle Einrichtung von Zugangsdaten authentifizieren kann.

## Was der MCP-Server bietet

Sobald verbunden ist, kann ein Coding-Agent:

- Übersetzungsstatus in allen Ihren Projekten abfragen
- Übersetzungen und Revisionen auslösen
- Konfiguration und Inhaltseinträge überprüfen
- Zugriff auf Projektkontext für intelligentere Code-Vorschläge

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
@ Lokale Entwicklung | `http://localhost:4050/mcp` @ |

## @ Authentifizierungsablauf

@ Der MCP-Server verwendet den Standard OAuth 2.1 Autorisierungscode-Flow mit PKCE. Sie müssen OAuth-Clients nicht manuell erstellen. Der Ablauf funktioniert wie folgt:

1. @ Der Agent erkennt Ihren Server über `/.well-known/oauth-authorization-server`
2. @ Es registriert sich als OAuth-Client über den dynamischen Registrierungs-Endpunkt
3. @ Es öffnet Ihren Browser für Anmeldung und Zustimmung
4. @ Nach Ihrer Bestätigung empfängt der Agent ein Zugriffstoken und fügt es allen MCP-Anfragen hinzu

## Hinzufügen von Glossia zu einem Coding-Agenten

### OpenAI Codex

Fügen Sie den Server in Ihre Codex-Konfigurationsdatei unter `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie den OAuth-Login aus:

```bash
codex mcp login glossia
```

Ihr Browser öffnet sich zur Authentifizierung. Nach der Bestätigung speichert Codex den Token lokal und verwendet ihn für zukünftige Sitzungen.

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

Fügen Sie den Server zu Ihren Claude Code MCP-Einstellungen hinzu (`.claude/settings.json` oder in die globale Einstellungsdatei):

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

### Andere MCP-Clients

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funktioniert. Die wesentlichen Anforderungen sind:

- **Transport**: HTTP-Streaming
- **Discovery**: Der Client muss OAuth 2.0 geschützte Ressourcemetadaten unterstützen ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Clientregistrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)") oder Client ID Metadokumente
- **Auth-Ablauf**: Autorisierungscode mit PKCE (S256)

Richten Sie den Client auf Ihre Glossia MCP Server-URL aus und lassen Sie die Entdeckung und Registrierung automatisch übernehmen.

## Discovery-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die MCP-Clients verwenden, um den OAuth-Ablauf zu starten:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Genehmigungstypen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Bereiche, Autorisierungsserver) |

## Ratenlimits

Die OAuth-Endpunkte durchsetzen Ratenlimits, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Ratenlimit überschritten wird, antwortet der Server mit HTTP 429 einem `Retry-After` Header.

## Fehlerbehebung

### Die Registrierung schlägt mit "invalid\_client\_metadata" fehl.

Der dynamische Registrierungsendpunkt akzeptiert nur spezifische `token_endpoint_auth_method` Werte. Öffentliche Clients (meiste Coding-Agenten) sollten senden `"none"`, übernimmt Glossia dies automatisch, indem auf Standardauthentifizierungsmethoden mit PKCE-Enforcement zurückgegriffen wird.

### "Ungültiger OAuth-Callback" nach Bestätigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und auf der von Ihnen konfigurierten URL erreichbar ist. Der Callback erfolgt auf einem lokalen Port, den der Coding-Agent vorübergehend öffnet. Firewalls oder VPNs können dies gelegentlich blockieren.

### Token-Austausch scheitert

Überprüfen Sie, ob das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers enthalten ist. Der Server muss S256 unterstützen, damit PKCE funktioniert. Glossia beinhaltet dies standardmäßig.

### Der Agent kann den Server nicht erreichen

Für die lokale Entwicklung stellen Sie sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port lauscht (Standard: 4050). Der MCP-Endpunkt muss vom Agenten-Prozess aus erreichbar sein.