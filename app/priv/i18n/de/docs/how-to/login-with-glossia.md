%{
  title: "Anmeldung mit Glossia",
  summary: "Ermöglichen Sie Benutzern, sich mit ihrem Glossia-Konto über OAuth 2.1 bei Ihrer App anzumelden.",
  category: "how-to",
  order: 2
}
---
Dieses Handbuch führt Sie durch das Hinzufügen von „Mit Glossia anmelden“ zu Ihrer Anwendung. Am Ende können sich Ihre Benutzer mit ihrem Glossia-Konto anmelden und Ihre Anwendung verfügt über ein Zugriffstoken, um die Glossia-API in deren Namen aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen für die Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und rufen Sie Ihr Konto-Dashboard auf.
2. Öffnen Sie den Bereich **API** in der Seitenleiste und klicken Sie auf **OAuth-Apps**.
3. Klicken Sie auf **Neue Anwendung**.
4. Geben Sie den **Namen** der Anwendung und die **Callback-URL** (auch Redirect-URI genannt) ein.
5. Klicken Sie auf **Anwendung erstellen**.

Notieren Sie nach der Erstellung die **Client-ID** und das **Client-Secret**. Das Secret wird nur einmal angezeigt, bewahren Sie es daher sicher auf.

### Option B: Dynamische Client-Registrierung

Senden Sie eine `POST`-Anfrage an `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

Die Antwort enthält `client_id` und `client_secret`.

## 2. Erzeugen Sie eine PKCE-Code-Challenge

Erzeugen Sie vor der Weiterleitung des Benutzers einen PKCE Code Verifier und eine Code-Challenge:

```javascript
function generateCodeVerifier() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function generateCodeChallenge(verifier) {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

const codeVerifier = generateCodeVerifier();
const codeChallenge = await generateCodeChallenge(codeVerifier);
// Store codeVerifier in your session -- you will need it in step 4
```

## 3. Leiten Sie den Benutzer zu Glossia weiter

Erstellen Sie die Autorisierungs-URL und leiten Sie den Browser des Benutzers weiter:

```
https://glossia.ai/oauth/authorize?
  response_type=code
  &client_id=YOUR_CLIENT_ID
  &redirect_uri=https://myapp.com/auth/callback
  &code_challenge=YOUR_CODE_CHALLENGE
  &code_challenge_method=S256
  &scope=user:read+project:read
  &state=RANDOM_STATE_VALUE
```

**Parameter:**

| Parameter | Erforderlich | Beschreibung |
|-----------|----------|-------------|
| `response_type` | Ja | Immer `code` |
| `client_id` | Ja | Die Client-ID Ihrer Anwendung |
| `redirect_uri` | Ja | Muss mit einer registrierten Callback-URL übereinstimmen |
| `code_challenge` | Ja | Die PKCE-Code-Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nein | Leerzeichengetrennte Liste von [Scopes](/docs/reference/apis/authentication). Standardmäßig minimaler Zugriff, falls weggelassen |
| `state` | Empfohlen | Eine zufällige Zeichenfolge zur Verhinderung von CSRF-Angriffen. Überprüfen Sie die Übereinstimmung, wenn der Benutzer zurückkehrt |

Der Benutzer sieht einen Zustimmungsbildschirm, der den Namen Ihrer Anwendung und die angeforderten Scopes anzeigt. Nach der Genehmigung leitet Glossia zurück zu Ihrer Callback-URL mit einem Autorisierungscode weiter.

## 4. Tauschen Sie den Code gegen Token ein

Wenn der Benutzer zu Ihrer Callback-URL zurückgeleitet wird, enthält die URL einen `code`-Parameter:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Überprüfen Sie zuerst, ob `state` mit dem in Schritt 3 gesendeten Wert übereinstimmt. Tauschen Sie dann den Code gegen Token ein:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://myapp.com/auth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code_verifier=YOUR_CODE_VERIFIER"
```

Die Antwort:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

Speichern Sie beide Token sicher. Das Zugriffstoken wird für API-Anfragen verwendet. Das Refresh-Token wird verwendet, um ein neues Zugriffstoken zu erhalten, wenn das aktuelle abläuft.

## 5. Rufen Sie die API im Namen des Benutzers auf

Verwenden Sie das Zugriffstoken, um authentifizierte API-Anfragen durchzuführen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen die Endpunkte, auf die Sie zugreifen können. Die Autorisierung auf Ressourcenebene gilt weiterhin. Beispielsweise kann ein Token mit `project:read` nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6. Aktualisieren Sie das Token

Wenn das Zugriffstoken abläuft, verwenden Sie das Refresh-Token, um ein neues zu erhalten, ohne den Benutzer erneut durch den Zustimmungsablauf zu führen:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Widerrufen Sie ein Token

Wenn ein Benutzer die Verbindung zu Ihrer App trennt oder Sie keinen Zugriff mehr benötigen, widerrufen Sie das Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Scopes auswählen

Fordern Sie nur die Scopes an, die Ihre Anwendung benötigt. Hier sind einige gängige Kombinationen:

| Anwendungsfall | Scopes |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Vollständiger Zugriff auf die Organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Siehe die [vollständige Scope-Referenz](/docs/reference/apis/authentication) für alle verfügbaren Scopes.

## Discovery-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch ermitteln, indem sie die Server-Metadaten abruft:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument mit `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` und weiteren Details zurück. Die Verwendung von Discovery macht Ihre Integration widerstandsfähig gegenüber Änderungen der Endpunkte.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer die Zustimmung verweigert oder während der Autorisierung ein Fehler auftritt, leitet Glossia mit einem `error`-Parameter an Ihre Callback-URL weiter:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | In der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Ein oder mehrere angeforderte Scopes sind ungültig |

### Token-Fehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehler-Body zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenbegrenzungen

Die OAuth-Endpunkte sind pro IP ratenbegrenzt. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Siehe die [Referenz zur Ratenbegrenzung](/docs/reference/apis/authentication) für Details.

## Sicherheits-Checkliste

Überprüfen Sie vor dem Übergang in die Produktion, ob Ihre Implementierung die folgenden Praktiken einhält:

- Verwenden Sie in der Produktion immer HTTPS für Callback-URLs
- Validieren Sie den Parameter `state` beim Callback, um CSRF zu verhindern
- Speichern Sie Token verschlüsselt im Ruhezustand (encrypted at rest)
- Legen Sie Token niemals in clientseitigem JavaScript oder in Browser-URLs offen
- Verwenden Sie nur die minimal erforderlichen Scopes
- Behandeln Sie den Ablauf von Token ordnungsgemäß mit Refresh-Token
- Widerrufen Sie Token, wenn Benutzer die Verbindung trennen oder ihr Konto löschen