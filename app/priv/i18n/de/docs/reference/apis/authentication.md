%{
  title: "Authentifizierung und Autorisierung",
  summary: "Wie Glossia Benutzer authentifiziert und den API-Zugriff autorisiert.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---
## Authentifizierungsmethoden

Glossia unterstützt zwei Authentifizierungsmethoden, je nach Kontext.

### Browser-Sitzungen

Bei der Anmeldung über das Webinterface verwendet Glossia eine Sitzungsauthentifizierung. Sie authentifizieren sich über einen Drittanbieter (GitHub oder GitLab) mit der [Assent](https://github.com/pow-auth/assent) Bibliothek. Nach einer erfolgreichen Anmeldung wird ein Sitzungs-Cookie gesetzt und für nachfolgende Anfragen verwendet.

### Bearer-Tokens (OAuth 2.1)

Für den API-Zugriff (z. B. über die CLI oder andere Tools) implementiert Glossia OAuth 2.1 mit dem Authorization-Code-Fluss und PKCE. Clients erhalten ein Bearer-Token und fügen es in den `Authorization` header:

    Authorization: Bearer <access_token>

## OAuth 2.1-Ablauf

### 1\. Dynamische Client-Registrierung

Clients registrieren sich selbst durch Aufruf `POST /oauth/register` mit ihren Metadaten. Dies folgt [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Der Server gibt zurück `client_id` und `client_secret`.

### 2\. Autorisierungsanfrage

Der Client umleitet den Benutzer zu `/oauth/authorize` mit PKCE-Parametern:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE ist für alle Clients erforderlich.** Nur die `S256` Challenge-Methode wird unterstützt.

### 3\. Token-Austausch

Nach der Benutzerfreigabe tauscht der Client den Autorisierungscode gegen Tokens bei `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

Die Antwort enthält ein Zugriffstoken und optional ein Refresh-Token.

### 4\. Token-Erneuerung

Wenn ein Zugriffstoken abläuft, verwenden Sie das Refresh-Token:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## Scopes

Scopes steuern, welche Aktionen ein Token ausführen kann. Sie folgen der `object:action` Muster.

| Bereich | Beschreibung |
|-------|-------------|
| `user:read` | Benutzerprofilinformationen lesen |
| `user:write` | Benutzerprofil aktualisieren |
| `account:read` | Organisationskonten auflisten, auf die Sie Zugriff haben |
| `organization:read` | Organisationsdetails einsehen (und Ihre Organisationen auflisten) |
| `organization:write` | Organisationen erstellen oder bearbeiten |
| `organization:delete` | Organisationen löschen |
| `organization:admin` | Organisationsverwaltung Aktionen |
| `members:read` | Organisation-Mitglieder und Einladungen einsehen |
| `members:write` | Organisation-Mitglieder und Einladungen verwalten |
| `project:read` | Projekte einsehen |
| `project:write` | Projekte erstellen oder aktualisieren |
| `project:admin` | Administrative Projektaktionen |
| `project:delete` | Projekte löschen |
| `voice:read` | Sprachkonfiguration anzeigen |
| `voice:write` | Stimmenkonfiguration erstellen oder aktualisieren |
| `voice:admin` | Administrative Aktionen für Stimmen |
| `glossary:read` | Terminologieeinträge lesen |
| `glossary:write` | Terminologieeinträge erstellen oder aktualisieren |
| `glossary:admin` | Terminologieeinstellungen verwalten |

## Autorisierungsmodell

Glossia erzwingt **zwei Ebenen** für die REST API und den MCP-Server:

1. **Scope-Prüfung**: das Access-Token muss die erforderlichen enthalten `object:action` Scope.
2. **Richtlinie auf Ressourcenebene**: der aktuelle Benutzer muss für die spezifische Ressource über `Glossia.Policy`.

Bereiche beschreiben die *maximale* Fähigkeit eines Tokens. Das Richtliniensystem durchsetzt die *tatsächliche* Berechtigung für eine spezifische Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer mit Zugriff auf eigene Ressourcen |
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

## Discovery-Endpunkte

Glossia veröffentlicht Metadaten an Standard-URLs, sodass Clients Endpunkte automatisch entdecken können.

### OAuth-Autorisierungsserver-Metadaten (RFC 8414)

    GET /.well-known/oauth-authorization-server

Gibt den Aussteller, Endpunkte, unterstützte Bereiche, Erlaubnistypen und Code-Challenge-Methoden zurück.

### Geschützte Ressourcen-Metadaten (RFC 9728)

    GET /.well-known/oauth-protected-resource

Gibt den Ressourcen-Identifikator, Autorisierungsserver, unterstützte Bereiche und Bearer-Methoden zurück.

## Ratenbegrenzung

OAuth-Endpunkte sind pro IP-Adresse limitiert:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Bei Rate-Limitierung antwortet der Server mit HTTP 429 (Zu viele Anfragen).