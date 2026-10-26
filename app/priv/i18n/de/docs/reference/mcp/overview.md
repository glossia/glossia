%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Coding-Agenten mit Ihren Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---

Glossia stellt einen [Modell-Kontext-Protokoll](https://modelcontextprotocol.io) (MCP) Server bereit, der Coding-Agenten die Interaktion mit Ihren Lokalisierungsprojekten ermöglicht. Der Server implementiert OAuth 2.1 mit PKCE und dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass MCP-kompatible Clients sich ohne manuelle Einrichtung von Anmeldedaten authentifizieren können.

## Was der MCP-Server bietet

Sobald verbunden, können Coding-Agenten Konten und Projekte auflisten, Projekte erstellen, Organisationsmitglieder und Einladungen verwalten, Stimme- und Glossar-Einstellungen lesen oder aktualisieren sowie Kontomodell und Token verwalten, unter Beachtung ihrer Berechtigungen.

Der Server bietet derzeit keine Tools zum Starten von Übersetzungen oder Revisionen oder zur Überprüfung des Übersetzungsstatus pro Datei an. Sehen Sie [Tools-Referenz](/docs/reference/mcp) für die verfügbaren Tools.

## Server-URL

Verbinden Sie sich mit dem gehosteten Dienst von Glossia unter `https://glossia.ai/mcp` . Glossia betreibt und pflegt diesen Endpoint; Sie konfigurieren lediglich die Verbindung in Ihrem Coding-Agenten.

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard OAuth 2.1 Autorisierungscode-Ablauf mit PKCE. Sie müssen OAuth-Clients manuell nicht erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Glossia über `https://glossia.ai/.well-known/oauth-authorization-server`
2. Es registriert sich selbst als OAuth-Client über den dynamischen Registrierungsendpunkt
3. Es öffnet Ihren Browser für Anmeldung und Zustimmung
4. Nach Ihrer Genehmigung erhält der Agent ein Access-Token und verbindet es mit allen MCP-Anfragen

## Glossia einem Coding-Agenten hinzufügen

### OpenAI Codex

Folgen Sie [Codex-Verbindungshilfe](https://developers.openai.com/codex/mcp) und fügen Sie den Server in Ihre Codex-Konfigurationsdatei unter `~/.codex/config.toml` ein:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie dann den OAuth-Anmeldung aus:

```bash
codex mcp login glossia
```

Ihr Browser öffnet sich für die Authentifizierung. Nach Genehmigung speichert Codex das Token lokal und nutzt es für zukünftige Sitzungen.

Um die Verbindung zu überprüfen:

```bash
codex mcp list
```

### Claude Code

Fügen Sie den gehosteten Server mit dem Befehl hinzu, der in [Claude Code Verbindungsanleitung](https://code.claude.com/docs/en/mcp) dokumentiert ist:

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Führen Sie `/mcp` in Claude Code aus und folgen Sie dem Browser-Authentifizierungsablauf.

### Andere MCP-Clients

Ein Client muss das von Glossia implementierte [Modell-Kontext-Protokoll-Autorisierungsablauf](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) unterstützen. Die Verbindung requires:

- **Transport**: Streamable HTTP
- **Entdeckung**: Der Client muss OAuth 2.0 Protected Resource Metadata ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Client-Registrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Authentifizierungsablauf**: Autorisierungscode mit PKCE (S256)

Weisen Sie den Client auf `https://glossia.ai/mcp` und lassen Sie ihn Entdeckung und Registrierung automatisch verwalten.

## Entdeckungs-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die MCP-Clients zum Bootstrapping des OAuth-Ablaufs verwenden:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Authentifizierungsserver-Metadaten (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Geschützter Ressourcen-Metadaten (Bereiche, Authentifizierungsserver) |

## Rate Limits

Die OAuth-Endpunkte erfordern Rate Limits, um Missbrauch zu verhindern:

| Endpoint | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate Limit überschritten wird, gibt der Server HTTP 429 mit einem `Retry-After`-Header zurück.

## Problembehandlung

### Die Registrierung schlägt fehl mit "invalid_client_metadata"

Der dynamische Registrierungsendpunkt akzeptiert nur bestimmte `token_endpoint_auth_method`-Werte. Öffentliche Clients (meiste Coding-Agenten) sollten `"none"` senden, was Glossia automatisch verarbeitet, indem es auf Standardauthentifizierungsmethoden mit PKCE-Enforcement zurückgreift.

### "Invalid OAuth callback" nach Genehmigung

Stellen Sie sicher, dass Ihr Coding-Agent `https://glossia.ai` erreichen kann. Der Callback erfolgt über einen lokalen Port, den der Coding-Agent vorübergehend auf Ihrem Computer öffnet. Glossia bleibt gehostet; dieser lokale Listener gehört Ihrem Agenten. Firewalls oder virtuelle private Netzwerke können gelegentlich den Callback blockieren.

### Der Token-Austausch schlägt fehl

Prüfen Sie, dass das `code_challenge_methods_supported`-Feld in der Autorisierungsserver-Metadaten vorhanden ist. Der Server muss S256-Unterstützung für PKCE ankündigen, damit es funktioniert. Glossia beinhaltet dies standardmäßig.

### Der Agent kann den Server nicht erreichen

Prüfen Sie, dass der konfigurierte Endpunkt `https://glossia.ai/mcp` lautet und dass Ihr Netzwerk Ihrem Coding-Agenten den Zugang ermöglicht. Wenn der gehoste Service weiterhin nicht verfügbar ist, kontaktieren Sie den Glossia-Support.
