%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglicht Benutzern, sich mit Ihrem Glossia-Konto über OAuth 2.1 in Ihre App einzuloggen.",
  category: "how-to",
  section: "platform",
  order: 2
}
---

Diese Anleitung führt Sie durch die Addition von "Login with Glossia" zu Ihrer Anwendung. Am Ende können Ihre Benutzer mit ihrem Glossia-Konto anmelden und Ihre App wird einen Zugriffstoken haben, um die Glossia-API im Namen der Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 with PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Möglichkeiten, um Ihre Anwendung zu registrieren:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Kontodashboard.
2. Öffnen Sie den **API**-Abschnitt aus der Seitenleiste und klicken Sie **OAuth apps**.
3. Klicken Sie **New application**.
4. Eingeben des Anwendungsnamens **name** und des Callback-URL **callback URL** (auch als Umleitungs-URI bezeichnet).
5. Klicken Sie **Create application**.

Nach der Erstellung notieren Sie sich den **Client ID** und das **Client secret**. Das Geheimnis wird einmal angezeigt, speichern Sie es daher sicher.

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

## 2. Generieren Sie eine PKCE-Code-Herausforderung

Bevor sie den Benutzer umleiten, generieren Sie einen PKCE-Code-Verifier und eine Herausforderung:

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

## 3. Leiten Sie den Benutzer zu Glossia um

Erstellen Sie die Autorisierungs-URL und leiten Sie den Browser des Benutzers um:

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

**Parameters:**

| Parameter | Benötigt | Beschreibung |
|-----------|----------|-------------|
| `response_type` | Ja | Immer `code` |
| `client_id` | Ja | Der Client-ID Ihrer Anwendung |
| `redirect_uri` | Ja | Muss mit einem registrierten Callback-URL übereinstimmen |
| `code_challenge` | Ja | Der PKCE-Code-Herausforderung (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nein | Eine durch Leerzeichen getrennte Liste von [scopes](/docs/reference/apis/authorization). Keine Aktionsskope werden gewährt, wenn sie weggelassen werden |
| `state` | Empfohlen | Eine Zufallszeichenfolge, um CSRF-Angriffe zu verhindern. Verifizieren Sie, dass sie übereinstimmt, wenn der Benutzer zurückkehrt |

Der Benutzer wird einen Zustimmungsbildschirm sehen, der den Namen Ihrer Anwendung und die angeforderten Scopes anzeigt. Nach ihrer Zustimmung leitet Glossia zurück zu Ihrem Callback-URL mit einem Autorisierungs-Code.

## 4. Tauschen Sie den Code gegen Tokens aus

Wenn der Benutzer zurück zu Ihrem Callback-URL umgeleitet wird, wird die URL einen `code`-Parameter enthalten:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Zuerst müssen Sie verifizieren, dass `state` mit dem übereinstimmt, was Sie in Schritt 3 gesendet haben. Tauschen Sie dann den Code gegen Tokens aus:

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

Speichern Sie beide Tokens sicher. Der Zugangs-Token wird für API-Anfragen verwendet. Der Refresh-Token wird verwendet, um einen neuen Zugangs-Token zu erhalten, wenn der aktuelle abläuft.

## 5. Rufen Sie die API im Namen des Benutzers auf

Verwenden Sie den Zugangs-Token, um authentifizierte API-Anfragen zu stellen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen, auf welche Endpunkte Sie zugreifen können. Die Autorisierung auf Ressourcenebene gilt weiterhin. Beispielsweise kann ein Token mit `project:read` nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6. Erfrischen Sie den Token

Wenn der Zugangs-Token abläuft, verwenden Sie den Refresh-Token, um einen neuen Token zu erhalten, ohne den Benutzer erneut durch den Zustimmungsablauf zu leiten:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Widerrufen Sie einen Token

Wenn ein Benutzer die Verbindung zu Ihrer Anwendung trennt oder Sie Zugriff nicht mehr benötigen, widerrufen Sie den Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Scopes auswählen

Fordern Sie nur die für Ihre Anwendung benötigten Scopes an. Hier sind einige gängige Kombinationen:

| Anwendungsfall | Scopes |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalt lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Organisationsressourcen verwalten | `user:read organization:read organization:write members:read members:write project:read project:write` |

Sehen Sie [Scopes-Referenz](/docs/reference/apis/authorization) für alle verfügbaren Scopes.

## Discovery-Endpunkte

Ihre Anwendung kann die Glossia-Endpunkte für OAuth automatisch entdecken, indem sie die Server-Metadaten abruft:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument mit den `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` und weiteren Details zurück. Die Nutzung der Discovery macht Ihre Integration gegenüber Änderungen der Endpunkte robust.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer der Zustimmung nicht zustimmt oder etwas während der Autorisierung schiefgeht, leitet Glossia Sie zurück zu Ihrer Callback-URL mit einem `error`-Parameter:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | Die Anforderung fehlt einen erforderlichen Parameter |
| `invalid_scope` | Eine oder mehrere angeforderte Scopes sind ungültig |

### Tokenfehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehler-Body zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Rate Limits

OAuth-Endpunkte werden pro IP limitiert. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Sehen Sie sich die [Rate-Limiting-Referenz](/docs/reference/apis/authentication) für Details an.

## Sicherheits-Checkliste

Bevor Sie in den Produktionsbetrieb gehen, prüfen Sie, ob Ihre Implementierung diesen Praktiken folgt:

- Verwenden Sie in der Produktion immer HTTPS für Callback-URLs:
- Validieren Sie den `state`-Parameter auf der Callback-URL, um CSRF zu verhindern:
- Speichern Sie Tokens verschlüsselt im Ruhezustand
- Offenbaren Sie Tokens niemals in client-seitigem JavaScript oder Browser-URLs:
- Verwenden Sie nur die für Sie benötigten Scopes.
- Verwenden Sie Refresh-Tokens für Token-Abläufe.
- Widerrufen Sie Tokens bei Abmeldung oder Kontolöschung.
