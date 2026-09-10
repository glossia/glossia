%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Coding-Agenten mit Ihren Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia bietet ein [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server, der es Coding-Agenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), so kann jeder MCP-kompatible Client authentifizieren, ohne manuelle Credential-Einstellung.

## Die vom MCP-Server bereitgestellten Funktionen

Nach der Verbindung kann ein Coding-Agent:

- Übersetzungsstatus über alle Projekte abfragen
- Übersetzungen und Revisionen auslösen
- Konfiguration und Inhaltseinträge überprüfen
- Zugriff auf Projekt-Kontext für intelligentere Codevorschläge

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard OAuth 2.1-Autorisierungscode-Flow mit PKCE. Sie müssen OAuth-Clients nicht manuell erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Ihren Server über `/.well-known/oauth-authorization-server`
2. Es registriert sich als OAuth-Client über den dynamischen Registrierungs-Endpunkt
3. Es öffnet Ihren Browser für die Anmeldung und Genehmigung
4. Nach Ihrer Genehmigung erhält der Agent einen Zugriffstoken und befügt es an alle MCP-Anfragen

## Hinzufügen von Glossia zu einem Coding-Agenten

### OpenAI Codex

Fügen Sie den Server in Ihre Codex-Konfigurationsdatei ein unter `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie dann den OAuth-Login aus:

```bash
codex mcp login glossia
```

Ihr Browser wird für die Authentifizierung geöffnet. Nach der Genehmigung speichert Codex das Token lokal und verwendet es für zukünftige Sitzungen.

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

Fügen Sie den Server in Ihre Claude Code MCP-Einstellungen (`.claude/settings.json` oder die globale Konfigurationsdatei):

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

Claude Code verwaltet den OAuth-Flow automatisch, wenn es sich das erste Mal verbindet.

### Andere MCP-Klienten

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) funktioniert. Die wichtigsten Anforderungen sind:

- **Transport**: Streaming-HTTP
- **Entdeckung**: Der Client muss OAuth 2.0 geschützte Ressourcenmetadaten unterstützen ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Clientregistrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client-ID-Metadokumente
- **Auth-Ablauf**: Autorisierungscode mit PKCE (S256)

Leiten Sie den Client auf die URL Ihres Glossia MCP-Servers und lassen Sie ihn die Discovery und Registrierung automatisch übernehmen.

## Discovery-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die MCP-Clients zur Initialisierung des OAuth-Ablaufs verwenden:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Bereiche, Autorisierungsserver) |

## Ratenbegrenzungen

Die OAuth-Endpunkte unterliegen Ratenbegrenzungen, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate Limit überschritten wird, antwortet der Server mit HTTP 429 und einem `Retry-After` Header.

## Fehlerbehebung

### Die Registrierung schlägt mit "invalid\_client\_metadata" fehl.

Der dynamische Registrierungsendpunkt akzeptiert nur bestimmte `token_endpoint_auth_method` Werte. Öffentliche Clients (die meisten Code-Agenten) sollten senden `"none"`, was Glossia automatisch durch Zurückgreifen auf Standard-Authentifizierungsmethoden mit PKCE-Durchsetzung abdeckt.

### "Ungültiger OAuth-Callback" nach Bestätigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und unter der von Ihnen konfigurierten URL erreichbar ist. Der Callback erfolgt auf einem lokalen Port, den der Coding-Agent vorübergehend öffnet. Firewalls oder VPNs können dies manchmal blockieren.

### Tokenaustausch schlägt fehl

Prüfen Sie, ob das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers vorhanden ist. Der Server muss die S256-Unterstützung anbieten, damit PKCE funktioniert. Glossia enthält dies standardmäßig.

### Der Agent kann den Server nicht erreichen

Für die lokale Entwicklung stellen Sie sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port lauscht (Standard: 4050). Der MCP-Endpunkt muss vom Agentenprozess aus erreichbar sein.