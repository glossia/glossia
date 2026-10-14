%{
  title: "Authentifizierung",
  summary: "Browser-Anmeldung, Zugriffstoken und Authentifizierungs-Endpunkte.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---

Dieser Abschnitt beschreibt [Offene Autorisierung](https://oauth.net/2.1/) (OAuth), [Beweisschlüssel zum Code-Austausch](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) und die [Anwendungsprogramm-Schnittstelle](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Die unten verlinkten Protokollspezifikationen werden als Anfragekommentare (RFCs) veröffentlicht.

## Authentifizierungsmethoden

Glossia unterstützt Browser-Sitzungen und Bearer-Tokens. Bearer-Tokens können über den unten beschriebenen Autorisierungsablauf erstellt werden oder als [Account-Tokens](/docs/reference/apis/account-tokens).

### Browser-Sitzungen

Beim Anmelden über die Benutzeroberfläche verwendet Glossia eine Sitzungs-basierte Authentifizierung. Sie authentifizieren sich über GitHub, GitLab, Google oder einen konfigurierten Organisations-Identitätsanbieter mit der [Assent](https://github.com/pow-auth/assent)-Bibliothek. Nach erfolgreicher Anmeldung wird ein Sitzungs-Cookie gesetzt und für nachfolgende Anweisungen verwendet.

Organisationen können Google Workspace oder Okta konfigurieren und ihre Arbeits-E-Mail-Domain verifizieren, bevor sie die automatische Registrierung erlauben. Siehe [Organisation-Anmeldung konfigurieren](/docs/how-to/organization-sign-in) für Aufstellungs- und Kontoverknüpfungsanforderungen.

### Bearer-Tokens (OAuth 2.1)

Für API-Zugang (wie von der CLI oder anderen Tools) implementiert Glossia OAuth 2.1 mit dem Authorization-Code-Fluss und PKCE. Clients erhalten einen Bearer-Token und fügen ihn im `Authorization`-Header hinzu:

```
Authorization: Bearer <access_token>
```

## OAuth 2.1-Fluss

### 1. Dynamische Client-Registrierung

Clients registrieren sich durch Aufruf von `POST /oauth/register` mit ihren Metadaten. Dies erfolgt nach [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia gibt `client_id` und `client_secret` zurück. Der `localhost`-Redirect in diesem Beispiel gehört während der Entwicklung zu Ihrer Anwendung. Produktionsanwendungen sollten eine eigene sichere Callback-Adresse registrieren.

### 2. Autorisierungsanfrage

Der Client leitet den Benutzer zu `/oauth/authorize` mit PKCE-Parametern um:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE ist für alle Clients erforderlich.** Nur der `S256`-Herausforderungsmodus wird unterstützt.

### 3. Token-Austausch

Nachdem der Benutzer zugestimmt hat, tauscht der Client den Autorisierungscode gegen Tokens bei `POST /oauth/token` ein:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

Die Antwort enthält ein Access-Token und ggf. ein Refresh-Token.

### 4. Token-Refresh

Wenn ein Access-Token abläuft, verwenden Sie das Refresh-Token:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Siehe [Autorisierung](/docs/reference/apis/authorization) für Berechtigungsbereiche, Mitgliedschafts- und Ressourcenzugriffsüberprüfung.

## Discovery-Endpunkte

Glossia veröffentlicht Metadaten an Standard-URLs, damit Clients Endpunkte automatisch finden können.

### OAuth-Autorisierungs-Server-Metadaten (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Gibt den Verleger, Endpunkte, unterstützte Scopes, Bewilligungstypen und Code-Herausforderungsmethoden zurück.

### Geschützte-Ressourcen-Metadaten (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Gibt den Ressourcen-Identifikator, Autorisierungs-Server, unterstützte Scopes und Bearer-Methoden zurück.

## Ratenbegrenzung

Registrierung ist durch Client-Adresse begrenzt. Token-, Widerrufs- und Inspektionsanfragen sind sowohl durch Client-Adresse als auch durch Client-Identifikator begrenzt:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5-Anfragen pro Minute |
| `POST /oauth/token` | 30-Anfragen pro Minute |
| `POST /oauth/revoke` | 30-Anfragen pro Minute |
| `POST /oauth/introspect` | 30-Anfragen pro Minute |

Bei Ratenbegrenzung gibt der Server HTTP 429 (Zu viele Anfragen) zurück.
