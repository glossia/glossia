%{
  title: "Authentifizierung und Autorisierung",
  summary: "Wie Glossia Benutzer authentifiziert und den API-Zugriff autorisiert.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---
## Authentifizierungsmethoden

Glossia unterstützt zwei Authentifizierungsmethoden, die je nach Kontext verwendet werden.

### Browser-Sitzungen

Wenn Sie sich über das Web-Interface anmelden, verwendet Glossia eine Sitzungsauthentifizierung. Sie authentifizieren sich über einen Drittanbieter (GitHub oder GitLab) unter Verwendung der [Assent](https://github.com/pow-auth/assent) Bibliothek. Nach einer erfolgreichen Anmeldung wird ein Sitzungs-Cookie gesetzt und für nachfolgende Anfragen verwendet.

### Bearer-Token (OAuth 2.1)

Für API-Zugriff (z. B. aus der CLI oder anderen Tools) implementiert Glossia OAuth 2.1 mit dem Authorization-Code-Flow und PKCE. Klients erhalten einen Bearer-Token und fügen ihn in den `Authorization` header:

    Authorization: Bearer <access_token>

## OAuth 2.1-Ablauf

### 1\. Dynamische Client-Registrierung

Clients registrieren sich selbst, indem sie `POST /oauth/register` mit ihren Metadaten. Dies folgt [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Der Server gibt zurück `client_id` und `client_secret`.

### 2\. Autorisierungsanfrage

Der Client leitet den Nutzer weiter zu `/oauth/authorize` mit PKCE-Parametern:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE ist für alle Clients erforderlich.** Nur die `S256` challenge-Methode wird unterstützt.

### 3\. Token-Austausch

Nachdem der Benutzer zugestimmt hat, tauscht der Client den Autorisierungscode gegen Tokens aus bei `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

Die Antwort enthält einen Zugriffstoken und optional einen Refresh-Token.

### 4\. Token-Erneuerung

Wenn ein Zugriffstoken abläuft, verwenden Sie den Refresh-Token:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Bereiche

Bereiche steuern, welche Aktionen ein Token ausführen kann. Sie folgen der `object:action` Muster.

| Umfang | Beschreibung |
|-------|-------------|
| `user:read` | Benutzerprofilinformationen lesen |
| `user:write` | Benutzerprofil aktualisieren |
| `account:read` | Organisationen auflisten, auf die Sie Zugriff haben |
| `organization:read` | Organisationsdetails einsehen (und Ihre Organisationen auflisten) |
| `organization:write` | Organisationen erstellen oder bearbeiten |
| `organization:delete` | Organisationen löschen |
| `organization:admin` | Verwaltungsaktionen der Organisation |
| `members:read` | Organisation-Mitglieder und Einladungen lesen |
| `members:write` | Organisation-Mitglieder und Einladungen verwalten |
| `project:read` | Projekte lesen |
| `project:write` | Projekte erstellen oder aktualisieren |
| `project:admin` | Administrative Projektaktionen |
| `project:delete` | Projekte löschen |
| `voice:read` | Stimmkonfiguration lesen |
| `voice:write` | Stimmenkonfiguration erstellen oder aktualisieren |
| `voice:admin` | Administrative Stimmen-Aktionen |
| `glossary:read` | Terminologie-Einträge lesen |
| `glossary:write` | Terminologie-Einträge erstellen oder aktualisieren |
| `glossary:admin` | Terminologie-Einstellungen verwalten |

## Autorisierungsmodell

Glossia erzwingt **zwei Schichten** für die REST API und den MCP-Server:

1. **Scope-Prüfung**: der Zugriffstoken muss den erforderlichen enthalten `object:action` Scope.
2. **Ressourcenbezogene Richtlinie**: der aktuelle Benutzer muss für die spezifische Ressource über `Glossia.Policy`,.

Bereiche repräsentieren die *maximal* Befugnis eines Tokens. Das Richtliniensystem durchsetzt die *tatsächlichen* Berechtigung für eine spezifische Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf eigene Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, die diese Ressource besitzt |
| `organization_admin` | Ein Administrator der Organisation, die die Ressource besitzt |
| `public_account` | Das Konto ist öffentlich (nur lesen) |

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

Glossia veröffentlicht Metadaten auf standardisierten, vorgegebenen URLs, sodass Clients Endpunkte automatisch entdecken können.

### OAuth Authorisierungsserver-Metadaten (RFC 8414)

    GET /.well-known/oauth-authorization-server

Gibt den Issuer, Endpunkte, unterstützte Scopes, Grant-Typen und Code-Challenge-Methoden zurück.

### Geschützte Ressource-Metadaten (RFC 9728)

    GET /.well-known/oauth-protected-resource

Gibt den Ressourcen-Identifikator, Authorisierungsserver, unterstützte Scopes und Bearer-Methoden zurück.

## Rate-Limiting

OAuth-Endpunkte sind pro IP-Adresse limitiert:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Bei Rate Limitierung wird HTTP 429 (Zu viele Anfragen) zurückgegeben.