%{
  title: "Authentifizierung und Autorisierung",
  summary: "Wie Glossia Benutzer authentifiziert und den API-Zugriff autorisiert.",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---
## Authentifizierungsmethoden

Glossia unterstützt je nach Kontext zwei Authentifizierungsmethoden.

### Browser-Sitzungen

Bei der Anmeldung über die Weboberfläche nutzt Glossia eine sitzungsbasierte Authentifizierung. Sie authentifizieren sich über einen Drittanbieter (GitHub oder GitLab) unter Verwendung der Bibliothek [Assent](https://github.com/pow-auth/assent). Nach einer erfolgreichen Anmeldung wird ein Session-Cookie gesetzt und für nachfolgende Anfragen verwendet.

### Bearer-Token (OAuth 2.1)

Für den API-Zugriff (beispielsweise über das CLI oder andere Tools) implementiert Glossia OAuth 2.1 mit dem Authorization Code Flow und PKCE. Clients erhalten ein Bearer-Token und übergeben dieses im Header `Authorization`:

```
Authorization: Bearer <access_token>
```

## OAuth 2.1-Ablauf

### 1. Dynamische Client-Registrierung

Clients registrieren sich selbst, indem sie `POST /oauth/register` mit ihren Metadaten aufrufen. Dies folgt [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Der Server gibt `client_id` und `client_secret` zurück.

### 2. Autorisierungsanfrage

Der Client leitet den Benutzer mit PKCE-Parametern an `/oauth/authorize` weiter:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE ist für alle Clients erforderlich.** Es wird nur die Challenge-Methode `S256` unterstützt.

### 3. Token-Austausch

Nachdem der Benutzer zugestimmt hat, tauscht der Client den Autorisierungscode an der Stelle `POST /oauth/token` gegen Token aus:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

Die Antwort enthält ein Access-Token und optional ein Refresh-Token.

### 4. Token-Aktualisierung

Wenn ein Access-Token abläuft, verwenden Sie das Refresh-Token:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## Scopes

Scopes steuern, welche Aktionen ein Token ausführen kann. Sie folgen dem Muster `object:action`.

| Scope | Beschreibung |
|-------|-------------|
| `user:read` | Benutzerprofil-Informationen lesen |
| `user:write` | Benutzerprofil aktualisieren |
| `account:read` | Organisationskonten auflisten, auf die Sie Zugriff haben |
| `organization:read` | Organisationsdetails lesen (und Ihre Organisationen auflisten) |
| `organization:write` | Organisationen erstellen oder aktualisieren |
| `organization:delete` | Organisationen löschen |
| `organization:admin` | Administrative Aktionen für Organisationen |
| `members:read` | Organisationsmitglieder und Einladungen lesen |
| `members:write` | Organisationsmitglieder und Einladungen verwalten |
| `project:read` | Projekte lesen |
| `project:write` | Projekte erstellen oder aktualisieren |
| `project:admin` | Administrative Aktionen für Projekte |
| `project:delete` | Projekte löschen |
| `voice:read` | Stimmenkonfiguration lesen |
| `voice:write` | Stimmenkonfiguration erstellen oder aktualisieren |
| `voice:admin` | Administrative Aktionen für Stimmen |
| `glossary:read` | Terminologieeinträge lesen |
| `glossary:write` | Terminologieeinträge erstellen oder aktualisieren |
| `glossary:admin` | Terminologieeinstellungen verwalten |

## Autorisierungsmodell

Glossia erzwingt **zwei Ebenen** für die REST-API und den MCP-Server:

1. **Scope-Prüfung**: Das Access-Token muss den erforderlichen Scope `object:action` enthalten.
2. **Richtlinie auf Ressourcenebene**: Der aktuelle Benutzer muss für die spezifische Ressource über `Glossia.Policy` autorisiert sein.

Scopes stellen die *maximale* Berechtigung eines Tokens dar. Das Richtliniensystem erzwingt die *tatsächliche* Berechtigung für eine spezifische Ressource.

### Rollen

| Rolle | Beschreibung |
|------|-------------|
| `self` | Der Benutzer, der auf seine eigenen Ressourcen zugreift |
| `organization_member` | Ein Mitglied der Organisation, der die Ressource gehört |
| `organization_admin` | Ein Administrator der Organisation, der die Ressource gehört |
| `public_account` | Das Konto ist öffentlich (schreibgeschützt) |

### Rollenberechtigungen

| Bereich | self | organization_member | organization_admin | public_account |
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

Glossia veröffentlicht Metadaten unter standardmäßigen, bekannten URLs, sodass Clients Endpunkte automatisch erkennen können.

### Metadaten des OAuth-Autorisierungsservers (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Gibt den Aussteller (Issuer), Endpunkte, unterstützte Scopes, Grant-Typen und Code-Challenge-Methoden zurück.

### Metadaten für geschützte Ressourcen (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Gibt die Ressourcenkennung, Autorisierungsserver, unterstützte Scopes und Bearer-Methoden zurück.

## Ratenbegrenzung

OAuth-Endpunkte sind pro IP-Adresse ratenbegrenzt:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Bei einer Ratenbegrenzung gibt der Server HTTP 429 (Too Many Requests) zurück.