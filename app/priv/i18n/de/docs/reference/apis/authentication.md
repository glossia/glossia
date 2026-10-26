%{
  title: "Authentifizierung",
  summary: "Browser-Anmeldung, Zugriffstoken und Authentifizierungsendpunkte.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---

Diese Seite beschreibt [Open Authorization](https://oauth.net/2.1/) (OAuth), [Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) und die [Programmierschnittstelle](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Die unten verlinkten Protokollspezifikationen werden als Requests for Comments (RFCs) veröffentlicht.

## Authentifizierungsmethoden

Glossia unterstützt Browser-Sitzungen und Bearer-Token. Bearer-Token können über den unten beschriebenen Autorisierungsablauf ausgestellt oder als [Kontotoken](/docs/reference/apis/account-tokens) erstellt werden.

### Browser-Sitzungen

Wenn Sie sich über das Web-Oberfläche anmelden, verwendet Glossia eine Sitzungsauthentifizierung. Sie authentifizieren sich über GitHub, GitLab, Google oder einen konfigurierten Organisations-Identitätsanbieter mittels der [Assent](https://github.com/pow-auth/assent)-Bibliothek. Nach einer erfolgreichen Anmeldung wird ein Sitzungs-Cookie gesetzt und für nachfolgende Anfragen verwendet.

Organisationen können Google Workspace oder Okta konfigurieren und ihre geschäftliche E-Mail-Domain verifizieren, bevor sie die automatische Zulassung erlauben. Siehe [Konfiguration der Organisationsanmeldung](/docs/how-to/organization-sign-in) für Einrichtungs- und Konto-Linkierungsanforderungen.

### Bearer-Token (OAuth 2.1)

Für API-Zugriff (z. B. von der CLI oder anderen Tools) implementiert Glossia OAuth 2.1 mit dem Authorization-Code-Fluss und PKCE. Clients erhalten ein Bearer-Token und beinhalten es im `Authorization`-Header:

```
Authorization: Bearer <access_token>
```

## OAuth 2.1-Ablauf

### 1. Registrierung dynamischer Clients

Clients registrieren sich, indem sie `POST /oauth/register` mit ihren Metadaten aufrufen. Dies folgt [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia gibt `client_id` und `client_secret` zurück. Der `localhost`-Umleitung in diesem Beispiel gehört zu Ihrer Anwendung während der Entwicklung. Produktionsanwendungen sollten ihre eigene sichere Callback-Adresse registrieren.

### 2. Autorisierungsanfrage

Der Client führt den Benutzer zu `/oauth/authorize` mit PKCE-Parametern weiter:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE ist für alle Clients erforderlich.** Nur die `S256`-Challenge-Methode wird unterstützt.

### 3. Token-Austausch

Nach der Genehmigung tauscht der Client den Autorisierungscode gegen Tokens an `POST /oauth/token` ein:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

Die Antwort enthält ein Access-Token und optional ein Refresh-Token.

### 4. Token-Erneuerung

Wenn ein Access-Token abläuft, verwenden Sie das Refresh-Token:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Siehe [Autorisierung](/docs/reference/apis/authorization) für Berechtigungs-Bereiche, Mitgliederzugriff und Ressourcen-Prüfungen auf Ressourcebene.

## Entdeckungsendpunkte

Glossia veröffentlicht Metadaten an standardisierten bekannten URLs, sodass Clients Endpunkte automatisch entdecken können.

### OAuth-Autorisierungs-Server-Metadaten (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Gibt den Anbieter, Endpunkte, unterstützte Bereiche, Gewährungstypen und Challenge-Methoden zurück.

### Geschützte Ressourcenmetadaten (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Gibt den Ressourcen-Identifizierer, Autorisierungs-Server, unterstützte Bereiche und Bearer-Methoden zurück.

## Ratenbegrenzung

Die Registrierung wird durch die Client-Adresse begrenzt. Token-, Widerruf- und Introspektionsanfragen werden sowohl durch die Client-Adresse als auch durch die Client-Identifizierung begrenzt:

| Endpunkt | Grenze |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Wenn die Rate begrenzt wird, gibt der Server HTTP 429 (Zu viele Anfragen) zurück.
