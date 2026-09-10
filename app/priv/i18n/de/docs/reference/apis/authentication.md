%{
  title: "Authentifizierung und Autorisierung",
  summary: "Wie Glossia Nutzer authentifiziert und API-Zugriff autorisiert.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---
## Authentifizierungsmethoden

Glossia unterstützt zwei Authentifizierungsmethoden je nach Kontext.

### Browser-Sitzungen

Wenn Sie sich über das Web-Interface anmelden, verwendet Glossia eine Sitzungsauthentifizierung. Sie authentifizieren sich über einen Drittanbieter-Provider (GitHub oder GitLab) unter Verwendung der [Assent](https://github.com/pow-auth/assent) Bibliothek. Nach einer erfolgreichen Anmeldung wird ein Sitzungs-Cookie festgelegt und für nachfolgende Anfragen verwendet.

### Bearer-Tokens (OAuth 2.1)

Für den API-Zugriff (beispielsweise von der CLI oder anderen Tools) implementiert Glossia OAuth 2.1 mit dem Authorization-Code-Flow und PKCE. Clients erhalten einen Bearer-Token und beinhalten ihn in das `Authorization` header:

    Authorization: Bearer <access_token>

## OAuth 2.1-Flow

### 1\. Dynamische Client-Registrierung

Clients registrieren sich dabei durch einen Aufruf `POST /oauth/register` mit ihren Metadaten. Dies entspricht [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Der Server gibt zurück `client_id` und `client_secret`.

### 2\. Autorisierungsanfrage

Der Client leitet den Benutzer weiter zu `/oauth/authorize` mit PKCE-Parametern:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE ist für alle Clients erforderlich.** Nur die `S256` Challenge-Methode wird unterstützt.

### 3\. Tokenaustausch

Nach der Benutzerbestätigung tauscht der Client den Autorisierungscode gegen Zugriffstokens aus bei `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

Die Antwort enthält einen Zugriffstoken und optional einen Refresh-Token.

### 4\. Token-Auffrischung

Wenn ein Zugriffstoken abläuft, verwenden Sie den Refresh-Token:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Bereiche

Bereiche steuern, welche Aktionen ein Token ausführen kann. Sie folgen dem `object:action` Muster.

| Bereich | Beschreibung |
|-------|-------------|
| `user:read` | Benutzerprofilinformationen lesen |
| `user:write` | Benutzerprofil aktualisieren |
| `account:read` | Organisationskonten auflisten, auf die Sie zugreifen können |
| `organization:read` | Organisationsdetails lesen (und Ihre Organisationen auflisten) |
| `organization:write` | Organisationen erstellen oder aktualisieren |
| `organization:delete` | Organisationen löschen |
| `organization:admin` | Administrative Aktionen für Organisationen |
| `members:read` | Organisationmitglieder und Einladungen lesen |
| `members:write` | Organisationmitglieder und Einladungen verwalten |
| `project:read` | Projekte lesen |
| `project:write` | Projekte erstellen oder aktualisieren |
| `project:admin` | Verwaltungsaktionen für Projekte |
| `project:delete` | Projekte löschen |
| `voice:read` | Stimmenkonfiguration lesen |
| `voice:write` | Stimmenkonfiguration erstellen oder aktualisieren |
| `voice:admin` | Administrative Aktionen für die Stimme |
| `glossary:read` | Terminologie-Einträge lesen |
| `glossary:write` | Terminologie-Einträge erstellen oder aktualisieren |
| `glossary:admin` | Terminologie-Einstellungen verwalten |

## Autorisierungsmodell

Glossia erzwingt **zwei Schichten** für die REST API und MCP-Server:

1. **Scope-Prüfung**: das Zugriffstoken muss das erforderliche `object:action` Scope.
2. **Richtlinie auf Ressourcenebene**: der aktuelle Benutzer muss für die spezifische Ressource über `Glossia.Policy`.

Bereiche repräsentieren die *maximale* Fähigkeit eines Tokens. Das Regelwerk erzwingt die *tatsächliche* Berechtigung für eine spezifische Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf seine eigenen Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, die die Ressource besitzt |
| `organization_admin` | Ein Administrator der Organisation, die die Ressource besitzt |
| `public_account` | Das Konto ist öffentlich (schreibgeschützt) |

### Rollenberechtigungen

| Bereich | self | organization\_member | organization\_admin | public\_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Ja | Ja | | |
| `user:write` | Ja | | | |
| `account:read` | | Ja | Ja | Ja |
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

Glossia veröffentlicht Metadaten an standardisierten, wohlbekannten URLs, sodass Clients Endpunkte automatisch entdecken können.

### OAuth Autorisierungs-Server-Metadaten (RFC 8414)

    GET /.well-known/oauth-authorization-server

Gibt den Aussteller, Endpunkte, unterstützte Bereiche, Grant-Typen und Code-Challenge-Methoden zurück.

### Metadaten für geschützte Ressourcen (RFC 9728)

    GET /.well-known/oauth-protected-resource

Gibt den Ressourcen-Identifikator, Autorisierungs-Server, unterstützte Bereiche und Bearer-Methoden zurück.

## Ratenbegrenzung

OAuth-Endpunkte sind pro IP-Adresse limitiert:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Bei Rate-Limiting gibt der Server HTTP 429 (Zu viele Anfragen) zurück.