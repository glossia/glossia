%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Code-Agenten mit Ihren Glossia-Projekten über das Modell-Kontext-Protokoll.",
  category: "Referenz",
  subcategory: "MCP",
  order: 1
}
---
Glossia stellt ein [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server bereit, der Coding-Agenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), so jeder MCP-kompatible Client sich authentifizieren kann, ohne manuelle Einrichtung von Anmeldeinformationen.

## Was der MCP-Server bereitstellt

Nach Verbindung kann ein Coding-Agent:

- Übersetzungsstatus über alle Ihre Projekte abfragen
- Translations und Revisionen auslösen
- Konfigurations- und Inhaltseinträge prüfen
- Projekt-Kontext für intelligentere Code-Vorschläge nutzen

## Server-URL

| Umgebung | URL |
|---|---|
| Produktion | `https://glossia.ai/mcp` |
| Lokale Entwicklung | `http://localhost:4050/mcp` |

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard OAuth 2.1-Autorisierungscode-Ablauf mit PKCE. Sie müssen OAuth-Clients nicht manuell erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Ihren Server über `/.well-known/oauth-authorization-server`
2. Es registriert sich selbst als OAuth-Client über den dynamischen Registrierungsendpunkt
3. Es öffnet Ihren Browser für Anmeldung und Zustimmung
4. Nach Ihrer Genehmigung empfängt der Agent ein Zugriffstoken und fügt es allen MCP-Anfragen hinzu.

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

Ihr Browser öffnet sich zur Authentifizierung. Nach der Genehmigung speichert Codex den Token lokal und verwendet es für zukünftige Sitzungen.

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

Fügen Sie den Server in Ihre Claude Code MCP-Einstellungen hinzu (`.claude/settings.json` oder in die globale Einstellungsdatei):

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

Claude Code übernimmt den OAuth-Ablauf automatisch beim ersten Anschluss.

### Andere MCP-Clients

Jeder Client, der die [MCP-Autorisierungsspezifikation](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) wird funktionieren. Die wichtigsten Anforderungen sind:

- **Transport**: Streambare HTTP
- **Discovery**: Der Client muss OAuth 2.0 Protected Resource Metadata unterstützen ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) oder Client-ID-Metadokumente
- **Auth-Flow**: Autorisierungscode mit PKCE (S256)

Leiten Sie den Client auf Ihre Glossia MCP-Server-URL und lassen Sie es Discovery und Registrierung automatisch übernehmen.

## Discovery-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die MCP-Clients zum Starten des OAuth-Flows verwenden:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten geschützter Ressourcen (Bereiche, Autorisierungsserver) |

## Ratenlimits

Die OAuth-Endpunkte durchsetzen Ratenlimits, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate Limit überschritten wird, gibt der Server HTTP 429 mit einem `Retry-After` Header.

## Fehlerbehebung

### Registrierung schlägt fehl mit "invalid\_client\_metadata"

Der dynamische Registrierungs-Endpunkt akzeptiert nur spezifische `token_endpoint_auth_method` Werte. Öffentliche Clients (meist Coding-Agenten) sollten senden `"none"`, wobei Glossia dies automatisch durch Rückgriff auf Standard-Authentifizierungsmethoden mit PKCE-Durchsetzung regelt.

### "Ungültiger OAuth-Zurückruf" nach der Genehmigung

Stellen Sie sicher, dass Ihr Glossia-Server läuft und unter der von Ihnen konfigurierten URL erreichbar ist. Der Callback erfolgt an einem lokalen Port, den der Coding-Agent vorübergehend öffnet. Firewalls oder VPNs können dies manchmal blockieren.

### Token-Austausch schlägt fehl

Stellen Sie sicher, dass das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers vorhanden ist. Der Server muss S256 unterstützen, damit PKCE funktioniert. Glossia enthält dies standardmäßig.

### Agent kann den Server nicht erreichen

Für die lokale Entwicklung stellen Sie sicher, dass der Phoenix-Server läuft (`mix phx.server`) und auf dem erwarteten Port lauscht (Standard: 4050). Der MCP-Endpunkt muss vom Agent-Prozess aus erreichbar sein.