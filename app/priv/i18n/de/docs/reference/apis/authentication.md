%{
  title: "Authentifizierung",
  summary: "Browser-Anmeldung, Zugriffstokens und Authentifizierungs-Endpunkte.",
  category: "Referenz",
  subcategory: "APIs",
  order: 1
}
---
Diese Seite beschreibt [Offene Autorisierung](https://oauth.net/2.1/) (OAuth), [Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE), und die [Programmierschnittstelle](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Die unten verlinkten Protokollspezifikationen werden als Requests for Comments (RFCs) veröffentlicht.

## Authentifizierungsmethoden

Glossia unterstützt Browser-Sitzungen und Bearer-Tokens. Bearer-Tokens können über den unten beschriebenen Authentifizierungsablauf ausgestellt oder als [Account-Tokens](/docs/reference/apis/account-tokens).

### Browser-Sitzungen

Wenn Sie sich über das Webinterface anmelden, verwendet Glossia die Sitzungsauthentifizierung. Sie authentifizieren sich über GitHub, GitLab, Google oder einen konfigurierten Unternehmensidentitätsanbieter unter Verwendung des [Assent](https://github.com/pow-auth/assent) Bibliothek. Nach einer erfolgreichen Anmeldung wird ein Sitzungs-Cookie gesetzt und für nachfolgende Anfragen verwendet.

Organisationen können Google Workspace oder Okta konfigurieren und ihre Arbeits-E-Mail-Domain verifizieren, bevor eine automatische Registrierung aktiviert wird. Siehe [Organisation-Anmeldung konfigurieren](/docs/how-to/organization-sign-in) zur Einrichtung und Kontoverknüpfung.

### Bearer-Tokens (OAuth 2.1)

Für den API-Zugriff (z. B. von der CLI oder anderen Tools) implementiert Glossia OAuth 2.1 mit dem Authorization-Code-Flow und PKCE. Clients erhalten ein Bearer-Token und fügen es in den `Authorization` Header:

    Authorization: Bearer <access_token>

## OAuth 2.1-Flow

### 1\. Dynamische Client-Registrierung

Clients registrieren sich selbst durch Aufruf `POST /oauth/register` mit ihren Metadaten. Dies folgt [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia gibt zurück `client_id` und `client_secret`. Die `localhost` Umleitung in diesem Beispiel gehört zu Ihrer Anwendung während der Entwicklung. Produktive Anwendungen sollten ihre eigenen sicheren Rückruf-Adressen registrieren.

### 2\. Autorisierungsanfrage

Der Client leitet den Benutzer weiter `/oauth/authorize` mit PKCE-Parametern:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE ist für alle Clients erforderlich.** Nur die `S256` Challenge-Methode wird unterstützt.

### 3\. Tokenaustausch

Nachdem der Benutzer zugestimmt hat, tauscht der Client den Autorisierungscode gegen Token an `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>

Die Antwort enthält einen Zugriffstoken und optional einen Refresh-Token.

### 4\. Token-Refresh

Wenn ein Zugriffstoken abläuft, verwenden Sie den Refresh-Token:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

Siehe [Autorisierung](/docs/reference/apis/authorization) für Berechtigungsstufen, Mitgliederzugriff und Prüfungen auf Ressourcenebene.

## Discovery-Endpunkte

Glossia veröffentlicht Metadaten an wohlbekannten, standardisierten URLs, sodass Clients Endpunkte automatisch entdecken können.

### OAuth-Autorisierungs-Server-Metadaten (RFC 8414)

    GET /.well-known/oauth-authorization-server

Gibt den Aussteller, Endpunkte, unterstützte Scopes, Grant-Typen und Code-Challenge-Methoden zurück.

### Metadaten für geschützte Ressourcen (RFC 9728)

    GET /.well-known/oauth-protected-resource

Gibt den Ressourcen-Identifikator, Autorisierungsserver, unterstützte Scopes und Bearer-Methoden zurück.

## Ratenbegrenzung

Die Registrierung wird durch die Client-Adresse limitiert. Token-, Widerruf- und Introspektionsanfragen werden sowohl durch die Client-Adresse als auch durch den Client-Identifikator limitiert:

| Endpunkt | Limit |
|----------|-------|
| `POST /oauth/register` | 5 Anfragen pro Minute |
| `POST /oauth/token` | 30 Anfragen pro Minute |
| `POST /oauth/revoke` | 30 Anfragen pro Minute |
| `POST /oauth/introspect` | 30 Anfragen pro Minute |

Beim Erreichen des Rate-Limits gibt der Server eine HTTP 429 (Zu viele Anfragen) zurück.