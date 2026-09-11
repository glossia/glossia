%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglichen Sie Nutzern, sich mit ihrem Glossia-Konto über OAuth 2.1 in Ihrer App anzumelden.",
  category: "Anleitungen",
  order: 2
}
---
Dieser Leitfaden führt Sie durch die Hinzufügung von "Anmeldung mit Glossia" zu Ihrer Anwendung. Bis zum Ende können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden und Ihre App verfügt über einen Zugriffstoken, um die Glossia-API im Namen ihrer Benutzer aufzurufen.

Glossia nutzt **OAuth 2.1 mit PKCE** (Beweisschlüssel für Code-Austausch). PKCE ist für alle Clients, einschließlich server-seitiger Anwendungen, erforderlich.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen zur Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Konto-Dashboard.
2. Öffnen Sie den **API** Bereich in der Seitenleiste und klicken Sie auf **OAuth-Anwendungen**.
3. Klicken Sie auf **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch als Redirect-URI bezeichnet).
5. Klicken **Anwendung erstellen**.

Nach der Erstellung merken Sie sich die **Client-ID** und **Client-Secret**. Das Secret wird einmal angezeigt, speichern Sie es daher sicher.

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

## 2\. Generiere eine PKCE-Code-Challenge

Bevor Sie den Benutzer umleiten, generieren Sie einen PKCE-Code-Verifizierer und eine Code-Challenge:

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
| `client_id` | Ja | Die Client-ID Ihrer Anwendung |
| `redirect_uri` | Ja | Muss einer registrierten Callback-URL entsprechen |
| `code_challenge` | Ja | Die PKCE Code Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nr. | Leerzeichengetrennte Liste von [Bereiche](/docs/reference/apis/authentication). Standardmäßig auf minimalen Zugriff, wenn nicht angegeben |
| `state` | Empfohlen | Eine zufällige Zeichenfolge zur Vermeidung von CSRF-Angriffen. Überprüfen Sie die Übereinstimmung, wenn der Benutzer zurückkehrt |

Der Benutzer wird eine Einwilligungsseite sehen, die Ihren Anwendungsnamen und die angeforderten Bereiche anzeigt. Nach der Genehmigung leitet Glossia den Benutzer mit einem Autorisierungscode zurück zu Ihrer Callback-URL.

## 4\. Tauschen Sie den Code gegen Token aus

Wenn der Benutzer zu Ihrer Callback-URL zurückgeleitet wird, enthält die URL einen `code` Parameter:

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

Speichern Sie beide Tokens sicher. Das Zugriffstoken wird für API-Anfragen verwendet. Das Auffrischungstoken wird verwendet, um ein neues Zugriffstoken zu erhalten, wenn dieses abläuft.

## 5\. Rufen Sie die API im Namen des Benutzers auf.

Verwenden Sie das Zugriffstoken für authentifizierte API-Anfragen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen, auf welche Endpunkte Sie zugreifen können. Die Ressourcenautorisierung gilt weiterhin - zum Beispiel, ein Token, der `project:read` kann nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6\. Aktualisieren Sie das Token

Wenn das Zugriffstoken abläuft, verwenden Sie das Auffrischungstoken, um ein neues Token zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf zu leiten:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Token widerrufen

Wenn ein Benutzer die Verbindung zu Ihrer App trennt oder Sie keinen Zugriff mehr benötigen, widerrufen Sie das Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Bereiche auswählen

Fordern Sie nur die Bereiche an, die Ihre Anwendung benötigt. Hier sind einige übliche Kombinationen:

| Anwendungsfälle | Bereiche |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Vollständiger Organisationszugriff | `user:read organization:read organization:write members:read members:write project:read project:write` |

Sehen Sie die [vollständige Scope-Referenz](/docs/reference/apis/authentication) für alle verfügbaren Bereiche.

## Discovery-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem sie die Server-Metadaten abruft:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument mit dem `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, und weitere Details. Die Entdeckung macht Ihre Integration resistent gegenüber Änderungen der Endpunkte.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Nutzer die Einwilligung ablehnt oder während der Autorisierung etwas schiefgeht, leitet Glossia zur Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Nutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | Der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Ein oder mehrere angeforderte Scopes sind ungültig |

### Tokenfehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerkörper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenbeschränkungen

OAuth-Endpunkte sind pro IP beschränkt. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Siehe die [Referenz zu Rate Limiting](/docs/reference/apis/authentication) für Details.

## Sicherheitscheckliste

Bevor Sie in Produktion gehen, überprüfen Sie, ob Ihre Implementierung diesen Praktiken folgt:

- Verwenden Sie in der Produktion immer HTTPS für Callback-URLs
- Validieren Sie den `state` Parameter im Callback, um CSRF zu verhindern
- Bewahren Sie Tokens verschlüsselt auf
- Token niemals in clientseitigem JavaScript oder Browser-URLs preisgeben
- Verwenden Sie nur die minimal notwendigen Scopes
- Verarbeiten Sie den Token-Ablauf problemlos mit Refresh-Tokens
- Widerrufen Sie Token, wenn Benutzer sich abmelden oder ihr Konto löschen