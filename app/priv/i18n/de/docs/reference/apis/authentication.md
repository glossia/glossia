%{
  title: "Authentifizierung",
  summary: "Browser-Anmeldung, Zugriffstoken und Authentifizierungs-Endpunkte.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---

Diese Seite beschreibt [Offene Autorisierung](https://oauth.net/2.1/) (OAuth), [Beweisschlüssel für Code-Tausch](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) und die [Anwendungsprogrammierschnittstelle](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Darunter verlinkte Protokollspezifikationen werden als Anfragen zur Kommentierung (RFCs) publiziert.

## Authentifizierungsmethoden

Glossia unterstützt Browser-Sitzungen und Bearer-Token. Bearer-Token können durch den unten beschriebenen Autorisierungsfluss ausgestellt oder als [Kontotokens](/docs/reference/apis/account-tokens) erstellt werden.

### Browser-Sitzungen

Wenn Sie sich über die Benutzeroberfläche anmelden, verwendet Glossia eine auf Sitzungen basierende Authentifizierung. Sie authentifizieren sich über GitHub, GitLab, Google oder einen konfigurierten Organisations-Identitätsanbieter mithilfe der [Assent](https://github.com/pow-auth/assent)-Bibliothek. Nach einer erfolgreichen Anmeldung wird ein Sitzungs-Cookie gesetzt und für nachfolgende Anfragen verwendet.

Organisationen können Google Workspace oder Okta konfigurieren und ihre Arbeits-E-Mail-Domain verifizieren, bevor sie die automatische Registrierung erlauben. Siehe [Organisationsanmeldung einrichten](/docs/how-to/organization-sign-in) für Setup- und Kontoverknüpfungsanforderungen.

### Bearer-Token (OAuth 2.1)

Für API-Zugriff (beispielsweise über die CLI oder andere Tools) implementiert Glossia OAuth 2.1 mit dem Autorisierungscode-Flow und PKCE. Clients erhalten einen Bearer-Token und schließen ihn in den `Authorization`-Header ein:

```
Authorization: Bearer <access_token>
```

## OAuth 2.1-Fluss

### 1. Dynamische Client-Registrierung

Clients registrieren sich selbst, indem sie `POST /oauth/register` mit ihren Metadaten aufrufen. Dies folgt [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia gibt `client_id` und `client_secret` zurück. Das `localhost`-Redirect in diesem Beispiel gehört zu Ihrer Anwendung während der Entwicklung. Produktionsanwendungen sollten ihre eigenen sicheren Callback-Adresse registrieren.

### 2. Autorisationsanfrage

Der Client leitet den Benutzer mit PKCE-Parametern auf `/oauth/authorize` weiter:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE ist für alle Clients erforderlich.** Nur die `S256`-Code-Challenge-Methode wird unterstützt.

### 3. Token-Austausch

Nachdem der Benutzer zugestimmt hat, tauscht der Client den Autorisierungscode für Token an `POST /oauth/token` aus:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

Die Antwort enthält einen Zugriffstoken und optional ein Refresh-Token.

### 4. Token-Erneuerung

Wenn ein Zugriffstoken abläuft, verwenden Sie den Refresh-Token:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Siehe [Autorisierung](/docs/reference/apis/authorization) für Berechtigungsbereiche, Mitgliedschaftszugriff und Ressourcen-Checks.

## Entdeckbare Endpunkte

Glossia veröffentlicht Metadaten an Standard-URLs, sodass Clients Endpunkte automatisch entdecken können.

### OAuth-Autorisierungsserver-Metadaten (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Es gibt den Herausgeber, Endpunkte, unterstützte Bereiche, Übergabearten und Code-Challenge-Methoden zurück.

### Geschützte Ressourcen-Metadaten (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Es gibt den Ressourcen-Identifier, Autorisierungsserver, unterstützte Bereiche und Bearer-Methoden zurück.

## Geschwindigkeitsbegrenzung

Die Registrierung ist nach Client-Adresse begrenzt. Token-, Widerruf- und Introspektionsanfragen sind von Client-Adresse und Client-Identifier begrenzt:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Bei Geschwindigkeitsbegrenzung sendet der Server HTTP 429 (Zu viele Anfragen) zurück.
