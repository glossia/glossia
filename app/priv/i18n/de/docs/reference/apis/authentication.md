%{
  title: "Authentifizierung und Autorisierung",
  summary: "Wie Glossia Benutzer authentifiziert und API-Zugriff autorisiert.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---
## Authentifizierungsmethoden

Glossia unterstützt zwei Authentifizierungsmethoden je nach Kontext.

### Browser-Sitzungen

Wenn Sie sich über das Webinterface anmelden, verwendet Glossia eine Sitzungsauthentifizierung. Sie authentifizieren sich über einen Drittanbieter (GitHub oder GitLab) unter Verwendung der [Assent](https://github.com/pow-auth/assent) Bibliothek. Nach einer erfolgreichen Anmeldung wird ein Sitzungs-Cookie gesetzt und für nachfolgende Anfragen verwendet.

### Bearer-Tokens (OAuth 2.1)

Für den API-Zugriff (beispielsweise von der CLI oder anderen Tools) implementiert Glossia OAuth 2.1 mit dem Authorization-Code-Flow und PKCE. Clients erhalten einen Bearer-Token und fügen ihn in den `Authorization` header:

    Authorization: Bearer <access_token>

## OAuth 2.1-Fluss

### 1\. Dynamische Client-Registrierung

Clients registrieren sich, indem sie `POST /oauth/register` mit ihren Metadaten. Dies folgt [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Der Server antwortet `client_id` und `client_secret`.

### 2\. Autorisierungsanfrage

Der Client leitet den Benutzer weiter zu `/oauth/authorize` mit PKCE-Parametern:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE ist für alle Clients erforderlich.** Nur die `S256` Code-Challenge-Methode wird unterstützt.

### 3\. Tokenaustausch

Nach der Benutzerfreigabe tauscht der Client den Autorisierungscode gegen Tokens bei `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

Die Antwort enthält ein Zugriffstoken und optional ein Refresh-Token.

### 4\. Tokenerneuerung

Wenn das Zugriffstoken abgelaufen ist, verwenden Sie das Refresh-Token:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Bereiche

Bereiche bestimmen, welche Aktionen ein Token ausführen kann. Sie folgen der `object:action` Muster.

| Bereich | Beschreibung |
|-------|-------------|
| `user:read` | Benutzerprofilinformationen lesen |
| `user:write` | Benutzerprofil aktualisieren |
| `account:read` | Organisation-Konten auflisten, auf die Sie zugreifen können |
| `organization:read` | Organisation-Details lesen (und Ihre Organisationen auflisten) |
| `organization:write` | Organisationen erstellen oder aktualisieren |
| `organization:delete` | Organisationen löschen |
| `organization:admin` | Verwaltungsmaßnahmen der Organisation |
| `members:read` | Organisationsmitglieder und Einladungen einsehen |
| `members:write` | Organisationsmitglieder und Einladungen verwalten |
| `project:read` | Projekte einsehen |
| `project:write` | Projekte erstellen oder aktualisieren |
| `project:admin` | Administrative Projektaktionen |
| `project:delete` | Projekte löschen |
| `voice:read` | Stimmenkonfiguration einsehen |
| `voice:write` | Stimme-Konfiguration erstellen oder aktualisieren |
| `voice:admin` | Verwaltungsaktionen für die Stimme |
| `glossary:read` | Terminologie-Einträge anzeigen |
| `glossary:write` | Terminologie-Einträge erstellen oder aktualisieren |
| `glossary:admin` | Terminologie-Einstellungen verwalten |

## Autorisierungsmodell

Glossia erzwingt **zwei Ebenen** für die REST API und den MCP Server:

1. **Scope-Prüfung**: der Zugriffstoken muss das erforderliche `object:action` Scope.
2. **Richtlinie auf Ressourcenebene**: der aktuelle Benutzer muss für die spezifische Ressource über `Glossia.Policy`.

Bereiche repräsentieren die *maximale* Fähigkeit eines Tokens. Das Richtlinien-System erzwingt die *tatsächliche* Berechtigung für eine spezifische Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf eigene Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, die die Ressource besitzt |
| `organization_admin` | Ein Administrator der Organisation, die die Ressource besitzt |
| `public_account` | Das Konto ist öffentlich (nur lesen) |

### Rollenberechtigungen

| Bereich | self | organization\_member | organization\_admin | public\_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Ja | Ja | | |
| `user:write` | Ja | | | |
| `account:read` | | Ja | Ja |
| `organization:read` | | Ja | Ja | |
| `organization:write` | | | Ja | |
| `organization:delete` | | | Ja | |
| `organization:admin` | | | Ja | |
| `members:read` | | Ja | Ja | |
| `members:write` | | | Ja | |
| `project:read` | | Ja | Ja | Ja |
| `project:write` | | | Ja | |
| `project:admin` | | | Ja | |
| `project:delete` | | | Ja | |
| `voice:read` | | Ja | Ja | Ja |
| `voice:write` | | | Ja | |
| `voice:admin` | | | Ja | |
| `glossary:read` | | Ja | Ja | |
| `glossary:write` | | | Ja | |
| `glossary:admin` | | | Ja | |

## Entdeckungs-Endpunkte

Glossia veröffentlicht Metadaten an standardisierten, wohlbekannten URLs, sodass Clients automatisch Endpunkte entdecken können.

### OAuth Autorisierungs-Server-Metadaten (RFC 8414)

    GET /.well-known/oauth-authorization-server

Gibt Issuer, Endpunkte, unterstützte Scopes, Grant-Typen und Code-Challenge-Methoden zurück.

### Geschützte-Ressourcen-Metadaten (RFC 9728)

    GET /.well-known/oauth-protected-resource

Gibt den Ressourcen-Identifikator, Autorisierungs-Server, unterstützte Scopes und Bearer-Methoden zurück.

## Anfragebegrenzung

OAuth-Endpunkte sind pro IP-Adresse limitiert:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Wenn rate limitiert, gibt der Server HTTP 429 (Zu viele Anfragen) zurück.