%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglicht Nutzern, sich mit ihrem Glossia-Konto über OAuth 2.1 in Ihrer App anzumelden.",
  category: "Anleitung",
  order: 2
}
---
Diese Anleitung führt Sie durch das Hinzufügen von "Login mit Glossia" zu Ihrer Anwendung. Zum Ende können Ihre Nutzer sich mit ihrem Glossia-Konto anmelden und Ihre App verfügt über einen Zugriffstoken, um die Glossia API im Namen der Nutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen zur Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Account-Dashboard.
2. Öffnen Sie den **API** Bereich aus der Seitenleiste und klicken Sie **OAuth-Anwendungen**.
3. Klicken Sie **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch als Umleitungs-URI bekannt).
5. Klicken **Anwendung erstellen**.

Nach der Erstellung, notieren Sie **Client-ID** und **Client-Schlüssel**. Der Schlüssel wird nur einmal angezeigt, speichern Sie ihn sicher.

### Option B: Dynamische Client-Registrierung

Senden Sie eine `POST` Anfrage an `/oauth/register`:

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

## 2\. Generieren Sie eine PKCE-Code-Challenge

Bevor Sie den Benutzer umleiten, generieren Sie einen PKCE-Code-Verifier und eine Code-Challenge:

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

Erstellen Sie die Autorisierungs-URL und leiten Sie den Browser des Benutzers weiter:

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
| `client_id` | Ja | Client-Id Ihrer Anwendung |
| `redirect_uri` | Ja | Muss einer registrierten Callback-URL entsprechen |
| `code_challenge` | Ja | Die PKCE-Code-Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nr. | Leerzeichengetrennte Liste der [Bereiche](/docs/reference/apis/authentication). Wird auf den minimalen Zugriff festgelegt, wenn nicht angegeben |
| `state` | Empfohlen | Eine zufällige Zeichenkette, um CSRF-Angriffe zu verhindern. Prüfen Sie, ob diese übereinstimmt, wenn der Benutzer zurückkehrt |

Der Benutzer wird eine Einwilligungsseite sehen, die Ihren Anwendungsname und die angeforderten Bereiche anzeigt. Nach ihrer Genehmigung leitet Glossia zurück auf Ihre Callback-URL mit einem Autorisierungscode.

## 4\. Tauschen Sie den Code gegen Token ein

Wenn der Benutzer auf Ihre Callback-URL umgeleitet wird, enthält die URL einen `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Zuerst prüfen Sie, dass `state` entspricht dem, was Sie in Schritt 3 gesendet haben. Tauschen Sie dann den Code gegen Tokens ein:

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

Speichern Sie beide Tokens sicher. Das Zugriffstoken wird für API-Anfragen verwendet. Das Auffrischungstoken dient dazu, ein neues Zugriffstoken zu erhalten, wenn das aktuelle abläuft.

## 5\. Rufen Sie die API im Namen des Benutzers auf

Verwenden Sie das Zugriffstoken, um authentifizierte API-Anfragen zu stellen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen, auf welche Endpunkte Sie zugreifen können. Die Autorisierung auf Ressourcenebene gilt weiterhin - zum Beispiel ein Token mit `project:read` nur Projekte lesen kann, auf die der Benutzer Zugriff hat.

## 6\. Erfrischen Sie das Token

Wenn das Zugriffstoken abläuft, verwenden Sie das Auffrischungstoken, um ein neues zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf zu schicken:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Token widerrufen

Wenn ein Nutzer die Verbindung zu Ihrer App unterbricht oder Sie keinen Zugriff mehr benötigen, widerrufen Sie das Token:

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
| Projekte und Inhalt lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Vollständiger Zugriff auf die Organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Siehe die [vollständige Bereiche-Referenz](/docs/reference/apis/authentication) für alle verfügbaren Bereiche.

## Discovery-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem es die Server-Metadaten abruft:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies liefert ein JSON-Dokument mit dem `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`\`, und weitere Details. Die Nutzung der Erkennung macht Ihre Integration widerstandsfähig gegenüber Änderungen an Endpunkten.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer die Einwilligung verweigert oder etwas während der Autorisierung schiefgeht, leitet Glossia zu Ihrer Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierung abgelehnt |
| `invalid_request` | Der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Eine oder mehrere angeforderte Berechtigungen sind ungültig |

### Tokenfehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerkörper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenbeschränkungen

OAuth-Endpunkte sind pro IP beschränkt. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Sehen Sie die [Referenz zur Rate Limiting](/docs/reference/apis/authentication) für Details.

## Sicherheits-Checkliste

Bevor Sie zur Produktion gehen, überprüfen Sie, dass Ihre Implementierung diese Praktiken einhält.

- Verwenden Sie für Callback-URLs in der Produktion immer HTTPS
- Validieren Sie den `state` Parameter am Callback, um CSRF zu verhindern
- Speichern Sie Tokens im Ruhezustand verschlüsselt
- Legen Sie Tokens niemals in client-side JavaScript oder Browser-URLs offen
- Verwenden Sie das minimale Set an benötigten Scopes
- Verwalten Sie Token-Abläufe sanft mit Refresh Tokens
- Entziehen Sie Tokens, wenn Benutzer sich abmelden oder ihr Account löschen