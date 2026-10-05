%{
  title: "Übersicht",
  summary:
    "Verbinden Sie Code-Agenten mit Ihren Glossia-Projekten über das Model Context Protocol.",
  category: "Referenz",
  subcategory: "mcp",
  order: 1
}
---
Glossia stellt eine [Model Context Protocol](https://modelcontextprotocol.io) (MCP)-Server, der Codingagenten ermöglicht, mit Ihren Lokalisierungsprojekten zu interagieren. Der Server implementiert OAuth 2.1 mit PKCE und Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), sodass sich jeder MCP-kompatible Client ohne manuelle Einrichtung von Anmeldeinformationen authentifizieren kann.

## Was der MCP-Server bietet

Nach der Verbindung kann ein Coding-Agent Accounts und Projekte auflisten, Projekte erstellen, Organisationsteilnehmer und Einladungen verwalten, Voice- und Glossar-Einstellungen lesen oder aktualisieren sowie Account-Modelle und Token verwalten, je nach seinen Berechtigungen.

Der Server bietet gegenwärtig keine Tools zum Starten von Übersetzungen oder Revisionen oder zur Prüfung des Übersetzungsstatus pro Datei an. Siehe die [Werkzeugreferenz](/docs/reference/mcp) für die verfügbaren Tools.

## Server-URL

Verbinden Sie sich mit dem gehosteten Dienst von Glossia unter `https://glossia.ai/mcp`. Glossia betreibt und verwaltet diesen Endpunkt; Sie konfigurieren nur die Verbindung in Ihrem Coding-Agenten.

## Authentifizierungsablauf

Der MCP-Server verwendet den Standard OAuth 2.1 Autorisierungscode-Flow mit PKCE. Sie müssen keine OAuth-Clienten manuell erstellen. Der Ablauf funktioniert wie folgt:

1. Der Agent entdeckt Glossia über `https://glossia.ai/.well-known/oauth-authorization-server`
2. Es registriert sich als OAuth-Client über den Endpunkt zur dynamischen Registrierung
3. Es öffnet Ihren Browser für Anmeldung und Einwilligung
4. Nach Ihrer Zustimmung erhält der Agent einen Zugriffstoken und fügt ihn allen MCP-Anfragen bei

## Glossia zu einem Coding-Agenten hinzufügen

### OpenAI Codex

Folgen Sie dem [Codex-Verbindungsleitfaden](https://developers.openai.com/codex/mcp), fügen Sie den Server in Ihre Codex-Konfigurationsdatei ein, an `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Führen Sie den OAuth-Login aus:

```bash
codex mcp login glossia
```

Ihr Browser wird sich für die Authentifizierung öffnen. Nach der Genehmigung speichert Codex das Token lokal und verwendet es für zukünftige Sitzungen.

Um die Verbindung zu überprüfen:

```bash
codex mcp list
```

### Claude Code

Fügen Sie den gehosteten Server mit dem Befehl hinzu, der in [die Verbindungsanleitung von Claude Code](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Ausführen `/mcp` in Claude Code ausführen und dem Browser-Authentifizierungsablauf folgen.

### Andere MCP-Clients

Ein Client muss den [Model Context Protocol-Autorisierungsablauf](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) von Glossia implementiert. Die Verbindung erfordert:

- **Transport**: Streamable HTTP
- **Entdeckung**: Der Client muss OAuth 2.0 Protected Resource Metadata unterstützen ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registrierung**: Dynamische Clientregistrierung ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Auth-Ablauf**: Autorisierungscode mit PKCE (S256)

Weisen Sie den Client an `https://glossia.ai/mcp` und lassen Sie es die Discovery und Registrierung automatisch übernehmen.

## Discovery-Endpunkte

Der Server veröffentlicht zwei Metadokumente, die MCP-Clients verwenden, um den OAuth-Ablauf zu initialisieren:

| Endpunkt | Beschreibung |
|---|---|
| `/.well-known/oauth-authorization-server` | Metadaten des Autorisierungsservers (Endpunkte, unterstützte Grant-Typen, PKCE-Methoden) |
| `/.well-known/oauth-protected-resource` | Metadaten der geschützten Ressource (Bereiche, Autorisierungsserver) |

## Ratenbegrenzungen

Die OAuth-Endpunkte setzen Ratenbegrenzungen durch, um Missbrauch zu verhindern:

| Endpunkt | Limit |
|---|---|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |

Wenn ein Rate Limit überschritten wird, antwortet der Server HTTP 429 mit einer `Retry-After` Kopfzeile.

## Fehlerbehebung

### Registrierung schlägt mit \\"invalid\_client\_metadata\\" fehl.

Der dynamische Registrierungs-Endpunkt akzeptiert nur bestimmte `token_endpoint_auth_method` Werte. Öffentliche Clients (die meisten Codingagenten) sollten senden `"none"`, was Glossia automatisch verarbeitet, indem es auf Standard-Authentifizierungsmethoden mit PKCE-Durchsetzung zurückfällt.

### "Ungültiger OAuth-Callback" nach Genehmigung

Stellen Sie sicher, dass Ihr Codingagent erreichen kann `https://glossia.ai`. Der Callback erfolgt an einem lokalen Port, den der Codingagent temporär auf Ihrem Computer öffnet. Glossia bleibt gehostet; dieser lokale Listener gehört Ihrem Codingagenten. Firewalls oder virtuelle private Netzwerke können den Callback manchmal blockieren.

### Token-Austausch fehlgeschlagen

Üüberprüfen Sie, dass das `code_challenge_methods_supported` Das Feld ist in den Metadaten des Autorisierungsservers enthalten. Der Server muss S256-Unterstützung für PKCE angeben, damit dies funktioniert. Glossia schließt dies standardmäßig ein.

### Der Agent kann den Server nicht erreichen

Prüfen Sie, dass der konfigurierte Endpunkt `https://glossia.ai/mcp` und dass Ihr Netzwerk Ihrem Coding-Agenten den Zugriff ermöglicht. Sollte der gehostete Dienst weiterhin nicht verfügbar sein, wenden Sie sich an den Glossia-Support.