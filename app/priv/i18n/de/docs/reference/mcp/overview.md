%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Coding-Agenten mit Ihren Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---

Glossia stellt einen [Model Context Protocol](https://modelcontextprotocol.io)-Server bereit, der es Coding-Agents ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und die Registrierung dynamischer Clients ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass jeder MCP-kompatible Client sich authentifizieren kann, ohne manuelle Einrichtung der Anmeldeinformationen.

## Was der MCP-Server bietet

Sobald verbunden, kann ein Coding-Agent Konten und Projekte auflisten, Projekte erstellen, Organisationsmitglieder und Einladungen verwalten, Stimmen- und Glossar-Einstellungen lesen oder aktualisieren sowie Kontomodell und Token verwalten, eingeschränkt durch dessen Berechtigungen.

Der Server stellt aktuell keine Tools zur Verfügung, um Übersetzungen oder Revisionen zu starten oder den Übersetzungsstatus pro Datei zu überprüfen. Siehe die [Tool-Referenz](/docs/reference/mcp) für die verfügbaren Tools.

## Server-URL

Verbinden Sie sich mit dem gehosteten Service von Glossia über `https://glossia.ai/mcp`. Glossia betreibt und unterhält diesen Endpunkt; Sie konfigurieren die Verbindung nur in Ihrem Coding-Agenten.

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard-OAuth 2.1-Zutritts-Code-Fluss mit PKCE. Sie müssen OAuth-Clients manuell nicht erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent findet Glossia über `https://glossia.ai/.well-known/oauth-authorization-server`.
2. Es registriert sich als OAuth-Client über den Endpunkt für die dynamische Registrierung.
3. Es öffnet Ihren Browser für Anmeldung und Zustimmung.
4. Nach Ihrer Bestätigung empfängt der Agent ein Zugriffstoken und hängt es an alle MCP-Anfragen an.

## Hinzufügen von Glossia zu einem Coding-Agenten

### OpenAI Codex

Folgen Sie dem [Codex-Verbindungshilfe](https://developers.openai.com/codex/mcp) und fügen Sie den Server in Ihre Codex-Konfigurationsdatei unter `~/.codex/config.toml` ein:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie dann den OAuth-Login aus:

```bash
codex mcp login glossia
```

Ihr Browser öffnet sich zur Authentifizierung. Nach Bestätigung speichert Codex das Token lokal und verwendet es für zukünftige Sitzungen.

Um die Verbindung zu überprüfen:

```bash
codex mcp list
```

### Claude Code

Fügen Sie den gehosteten Server mit dem in [Verbindungshilfe für Claude Code](https://code.claude.com/docs/en/mcp) dokumentierten Befehl hinzu:

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Führen Sie `/mcp` in Claude Code aus und folgen Sie dem Browser-Authentifizierungsablauf.

### Andere MCP-Clients

Ein Client muss den [Model Context Protocol-Zugriffsablauf](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) unterstützen, der von Glossia implementiert wird. Die Verbindung erfordert:

- **Transport**: HTTP-Streaming
- **Entdeckung**: Der Client muss OAuth 2.0 Protected Resource Metadaten ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728)) unterstützen.
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Authentifizierungsablauf**: Autorisierungscode mit PKCE (S256)

Leiten Sie den Client auf `https://glossia.ai/mcp` und lassen Sie es die Entdeckung und Registrierung automatisch durchführen.

## Entdeckungs-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die MCP-Clients verwenden, um den OAuth-Ablauf zu starten:

| Endpoint | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Geschütztes Ressourcen-Metadaten (Bereiche, Autorisierungsserver) |

## Rate Limits

Die OAuth-Endstellen erzwingen Rate Limits, um Missbrauch zu verhindern:

| Endpoint | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate Limit überschritten wird, gibt der Server HTTP 429 mit einem `Retry-After`-Header zurück.

## Fehlerbehebung

### Die Registrierung schlägt mit "invalid_client_metadata" fehl.

Der Endpunkt für die dynamische Registrierung akzeptiert nur spezifische `token_endpoint_auth_method`-Werte. Öffentliche Clients (meist Coding-Agenten) sollten `"none"` senden; worauf Glossia automatisch zurückfällt, Standard-Authentifizierungsmethoden mit PKCE-Enforcement.

### "Ungültiges OAuth-Callback" nach der Bestätigung

Stellen Sie sicher, dass Ihr Coding-Agent `https://glossia.ai` erreichen kann. Der Rückruf findet auf einem lokalen Port statt, den Ihr Coding-Agent vorübergehend auf Ihrem Computer öffnet. Glossia bleibt gehostet; dieser lokale Listener gehört Ihrem Agent. Firewalls oder virtuelle private Netzwerke können manchmal den Rückruf blockieren.

### Der Token-Austausch fällt fehl

Stellen Sie sicher, dass das Feld `code_challenge_methods_supported` in den Metadaten des Autorisierungsservers vorhanden ist. Der Server muss S256-Unterstützung für PKCE anbieten. Glossia schließt dies durch Standard.

### Agent kann den Server nicht erreichen

Stellen Sie sicher, dass der konfigurierte Endpunkt `https://glossia.ai/mcp` ist und dass Ihr Netzwerk Ihrem Coding-Agenten Zugriff darauf gewährt. Wenn der gehostete Dienst weiterhin unavailable ist, wenden Sie sich an den Glossia-Support.
