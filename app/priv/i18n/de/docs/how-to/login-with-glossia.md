%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglichen Sie Benutzern, sich in Ihrer App mit ihrem Glossia-Konto über OAuth 2.1 anzumelden.",
  category: "Anleitung",
  order: 2
}
---
Dieser Leitfaden führt Sie durch das Hinzufügen von "Login with Glossia" zu Ihrer Anwendung. Bis am Ende können sich Ihre Benutzer mit ihrem Glossia-Konto anmelden und Ihre Anwendung erhält ein Zugriffstoken, um die Glossia-API im Namen der Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1\. Registrieren Ihrer OAuth-Anwendung

Sie haben zwei Möglichkeiten, Ihre Anwendung zu registrieren:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Kontodashboard.
2. Öffnen Sie **API** Sektion aus der Seitenleiste und klicken Sie **OAuth-Anwendungen**.
3. Klicken Sie **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch bekannt als Redirect-URI).
5. Klicken **Anwendung erstellen**.

Nach der Erstellung notieren Sie **Client ID** und **Client secret**. Das Geheimnis wird nur einmal angezeigt, speichern Sie es daher sicher.

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

## 2\. Erstellen Sie einen PKCE Code-Challenge

Bevor Sie den Benutzer umleiten, erstellen Sie einen PKCE Code-Verifier und Code-Challenge:

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

## 3\. Leiten Sie den Benutzer zu Glossia um

Erstellen Sie die Autorisierungs-URL und leiten Sie den Browser des Benutzers um:

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
| `client_id` | Ja | Client-ID Ihrer Anwendung |
| `redirect_uri` | Ja | Muss einer registrierten Callback-URL entsprechen |
| `code_challenge` | Ja | Der PKCE-Code-Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Keine | durch Leerzeichen getrennte Liste von [scopes](/docs/reference/apis/authentication). Standardmäßig minimaler Zugriff, wenn nicht angegeben |
| `state` | Empfohlen | Eine zufällige Zeichenkette zur Verhinderung von CSRF-Angriffen. Verifizieren Sie, dass sie übereinstimmt, wenn der Benutzer zurückkehrt |

Der Benutzer sieht einen Einwilligungs-Bildschirm, der Ihren Anwendungsname und die angeforderten scopes anzeigt. Nach ihrer Genehmigung leitet Glossia zurück zu Ihrer Callback-URL mit einem Autorisierungscode.

## 4\. Code gegen Token eintauschen

Wenn der Benutzer zu Ihrer Callback-URL zurückgeleitet wird, enthält die URL einen `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Prüfen Sie zuerst, dass `state` dies dem entspricht, was Sie in Schritt 3 gesendet haben. Tauschen Sie danach den Code gegen Tokens aus:

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

Speichern Sie beide Token sicher. Das Zugriffstoken wird für API-Anfragen verwendet. Das Refresh-Token wird genutzt, um ein neues Zugriffstoken zu erhalten, wenn das aktuelle Token abläuft.

## 5\. Rufen Sie die API im Namen des Benutzers auf

Verwenden Sie das Zugriffstoken, um authentifizierte API-Anfragen zu stellen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Token-Berechtigungen begrenzen, welche Endpunkte Sie zugreifen können. Die Ressourcen-Berechtigungen bleiben bestehen - zum Beispiel ein Token mit `project:read` kann nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6\. Aktualisieren Sie das Token

Wenn das Zugriffstoken abläuft, verwenden Sie das Refresh-Token, um ein neues zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf zu schicken:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Token widerrufen

Wenn ein Nutzer Ihre App abmeldet oder Sie keinen Zugriff mehr benötigen, widerrufen Sie den Token:

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
| Projekte und Inhalte einsehen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Vollzugriff auf die Organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Siehe die [vollständige Scope-Referenz](/docs/reference/apis/authentication) für alle verfügbaren Bereiche.

## Entdeckungs-Endpunkte

Ihre Anwendung kann die Glossia OAuth-Endpunkte automatisch entdecken, indem die Servermetadaten abgerufen werden:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies liefert ein JSON-Dokument mit dem `authorization_endpoint`Das neu zusammengeführte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textliterals ergab ungültiges JSON `token_endpoint`Das zuvor zusammengeführte Dokument hat die Validierung nicht bestanden: Die Markdown-Text-Literal-Wiederherstellung muss ein JSON-String-Array mit entsprechender Länge zurückgeben. `revocation_endpoint`, und weitere Details. Discovery ermöglicht Ihrer Integration eine Widerstandsfähigkeit gegenüber Änderungen des Endpunkts.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer der Zustimmung verweigert oder während der Autorisierung etwas schiefgeht, leitet Glossia zu Ihrer Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | Der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Ein oder mehrere angeforderte Bereiche sind ungültig |

### Token-Fehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerkörper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Rate-Limits

OAuth-Endpunkte sind pro IP nach Rate-Limits begrenzt. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Sehen Sie die [Referenz für Rate Limiting](/docs/reference/apis/authentication) für Details.

## Sicherheitscheckliste

Bevor Sie in Produktion gehen, überprüfen Sie, dass Ihre Implementierung diesen Praktiken folgt:

- Verwenden Sie immer HTTPS für Callback-URLs in der Produktion
- Validieren Sie den `state` Parameter auf dem Callback, um CSRF zu verhindern
- Speichern Sie Tokens verschlüsselt im Ruhezustand
- Legen Sie Token niemals in Client-Side-JavaScript oder Browser-URLs offen.
- Verwenden Sie nur die benötigten Mindestscopes.
- Verwalten Sie Token-Abläufe reibungslos mit Refresh-Tokens.
- Widerrufen Sie Token, wenn sich Nutzer abmelden oder ihr Konto löschen.