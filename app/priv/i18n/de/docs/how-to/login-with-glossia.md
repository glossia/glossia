%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglicht Benutzern, sich in Ihrer App mit ihrem Glossia-Konto über OAuth 2.1 anzumelden.",
  category: "Anleitungen",
  order: 2
}
---
Diese Anleitung führt Sie durch die Hinzufügung von "Login with Glossia" zu Ihrer Anwendung. Am Ende können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden und Ihre Anwendung verfügt über einen Zugriffstoken, um im Namen der Benutzer die Glossia API aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen für die Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Kontodashboard.
2. Öffnen Sie die **API** Bereich in der Seitenleiste und klicken **OAuth-Anwendungen**.
3. Klicken **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch Umleitungs-URI genannt.).
5. Klicken **Anwendung erstellen**.

Nach der Erstellung, notieren Sie **Client ID** und **Client Secret**. Der Secret wird einmal angezeigt, speichern Sie ihn sicher.

### Option B: Dynamische Client-Registrierung

Senden Sie `POST` eine Anfrage an `/oauth/register`:

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

## 2\. Generieren Sie eine PKCE-Code-Herausforderung

Bevor Sie den Benutzer weiterleiten, generieren Sie einen PKCE-Code-Prüfwert und eine Code-Herausforderung:

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

## 3\. Leiten Sie den Benutzer zu Glossia weiter

Erstellen Sie die Autorisierungs-URL und leiten Sie den Browser des Nutzers weiter:

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**Parameter:**

| Parameter | Erforderlich | Beschreibung |
|-----------|----------|-------------|
| `response_type` | Ja | Immer `code` |
| `client_id` | Ja | Die Client-ID Ihrer Anwendung |
| `redirect_uri` | Ja | Muss einer registrierten Callback-URL entsprechen |
| `code_challenge` | Ja | Die PKCE-Code-Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Name | Durch Leerzeichen getrennte Liste von [Bereiche](/docs/reference/apis/authentication). Standardmäßig auf minimalen Zugriff gesetzt, wenn weggelassen. |
| `state` | Empfohlen | Eine zufällige Zeichenfolge, um CSRF-Angriffe zu verhindern. Überprüfen Sie, ob diese übereinstimmen, wenn der Benutzer zurückkehrt |

Der Benutzer sieht einen Einwilligungsbildschirm, der Ihren Anwendungsname und die angeforderten Bereiche anzeigt. Nach der Genehmigung leitet Glossia zur Callback-URL mit einem Autorisierungscode weiter.

## 4\. Tauschen Sie den Code gegen Tokens aus

Wenn der Benutzer an Ihre Callback-URL weitergeleitet wird, enthält die URL einen `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Prüfen Sie zunächst, dass `state` es dem entspricht, was Sie in Schritt 3 gesendet haben. Tauschen Sie anschließend den Code gegen Tokens ein:

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

Speichern Sie beide Tokens sicher. Der Access-Token wird für API-Anfragen verwendet. Der Refresh-Token wird verwendet, um ein neues Access-Token zu erhalten, wenn das aktuelle Token abläuft.

## 5\. API im Namen des Benutzers aufrufen

Verwenden Sie den Access-Token, um authentifizierte API-Anfragen zu stellen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Token-Bereiche begrenzen, welche Endpunkte Sie erreichen können. Ressourcenlevel-Autorisierung gilt weiterhin - zum Beispiel, ein Token mit `project:read` kann nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6\. Token erneuern

When the access token expires, use the refresh token to get a new one without sending the user through the consent flow again: -\> Wenn der Access-Token abläuft, verwenden Sie den Refresh-Token, um ein neues zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf zu senden:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Ein Token widerrufen

Wenn ein Benutzer sich aus Ihrer App abmeldet oder Sie keinen Zugriff mehr benötigen, widerrufen Sie das Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Bereiche auswählen

Fordern Sie nur die Bereiche an, die Ihre Anwendung benötigt. Hier sind einige gängige Kombinationen:

| Anwendungsfall | Bereiche |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Voller Organisationszugriff | `user:read organization:read organization:write members:read members:write project:read project:write` |

Sehen Sie die [Referenz für volle Berechtigungen](/docs/reference/apis/authentication) für alle verfügbaren Bereiche.

## Discovery-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem sie die Server-Metadaten abrufen:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument mit dem `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, und weitere Details. Die Verwendung von Discovery macht Ihre Integration gegenüber Änderungen an Endpunkten widerstandsfähig.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer die Einwilligung verweigert oder während der Autorisierung ein Fehler auftritt, leitet Glossia Sie an Ihre callback URL weiter mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | Der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Eine oder mehrere angeforderte Bereiche sind ungültig |

### Token-Fehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerinhalt zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenlimits

OAuth-Endpunkte sind pro IP Ratenlimitiert. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Sehen Sie das [Referenz zur Ratenbegrenzung](/docs/reference/apis/authentication) für Details.

## Sicherheitscheckliste

Bevor Sie in die Produktion gehen, überprüfen Sie, dass Ihre Implementierung diese Praktiken einhält:

- Verwenden Sie in der Produktion immer HTTPS für Callback-URLs
- Validieren Sie den `state` Parameter auf dem Callback, um CSRF zu verhindern
- Speichern Sie Tokens verschlüsselt im Ruhezustand
- Token niemals in clientseitigem JavaScript oder Browser-URLs offenlegen
- Verwenden Sie die minimal notwendigen Berechtigungen
- Verwalten Sie Token-Abläufe nahtlos mit Refresh-Tokens
- Widerrufen Sie Tokens, wenn sich Benutzer abmelden oder ihr Konto löschen