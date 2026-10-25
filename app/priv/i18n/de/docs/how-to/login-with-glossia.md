%{
  title: "Mit Glossia anmelden",
  summary:
    "Lassen Sie Benutzer sich mit ihrem Glossia-Konto über OAuth 2.1 in Ihrer App anmelden.",
  category: "Anleitung",
  section: "platform",
  order: 2
}
---

Diese Anleitung zeigt dir, how du "Login mit Glossia" zu deiner Anwendung hinzufügst. Am Ende können deine Nutzer sich mit ihrem Glossia-Konto anmelden und deine App verfügt über einen Zugriffstoken, der die Glossia-API im Namen der Nutzer aufzurufen kann.

Glossia verwendet **OAuth 2.1 mit PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1. Registrieren Sie deine OAuth-Anwendung

Du hast zwei Möglichkeiten, deine Anwendung zu registrieren:

### Option A: Über das Dashboard (empfohlen)

1. Melde dich bei Glossia an und gehe zu deinem ACCOUNT-Dashboard.
2. Öffne den **API**-Bereich aus der Seitenleiste und klicke auf **OAuth apps**.
3. Klicke auf **New application**.
4. Fülle das Feld **Name** der Anwendung und das Feld **Callback-URL** (auch als Umleitungs-URI bezeichnet) aus.
5. Klicke auf **Eine Anwendung erstellen**.

Notiere nach der Erstellung den **Client-ID** und den **Client-Secret**. Der Secret wird einmal angezeigt, speichere ihn daher sicher.

### Option B: Dynamische Client-Registrierung

Sende eine `POST`-Anforderung zu `/oauth/register`:

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

## 2. Generiere einen PKCE-Code-Herausforderung

Bevor du den Benutzer umleitest, generiere einen PKCE-Code-Verifier und -Challenge:

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

## 3. Leite den Benutzer zu Glossia weiter

Baue die Autorisierungs-URL und leite den Browser des Benutzers weiter:

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
| `client_id` | Ja | Die Client-ID deiner Anwendung |
| `redirect_uri` | Ja | Muss mit einer registrierten Callback-URL übereinstimmen |
| `code_challenge` | Ja | Der PKCE Code Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nein | Leerzeichengetrennte Liste von [Scopes](/docs/reference/apis/authorization). Es werden keine Aktionen-Scopes gewährt, wenn nicht angegeben. |
| `state` | Empfohlen | Eine zufällige Zeichenkette zum Verhindern von CSRF-Angriffen. Verifizieren Sie, dass sie übereinstimmen, wenn der Benutzer zurückkehrt. |

Der Benutzer sieht einen Bildschirm der Zustimmung, der deinen Anwendangsnamen und die angeforderten Scopes zeigt. Nach ihrer Zustimmung leitet Glossia zurück zu deiner Callback-URL mit einem Autorisierungscode.

## 4. Tausche den Code gegen Tokens aus

Wenn der Benutzer zu deiner Callback-URL zurückgeleitet wird, enthält die URL einen `code`-Parameter:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Verifiziere zunächst, dass `state` mit dem übereinstimmt, das du in Schritt 3 gesendet hast. Tausche dann den Code gegen Tokens aus:

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

Speichere beide Tokens sicher. Der Zugriffstoken wird für API-Anfragen verwendet. Der Refresh-Token wird verwendet, um einen neuen Zugriffstoken zu erhalten, wenn der aktuelle abläuft.

## 5. Rufe die API im Namen des Benutzers auf

Verwende den Zugriffstoken, um authentisierte API-Anfragen zu stellen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens limitieren, auf welche Endpunkte du zugreifen kannst. ©opyright-Nutzungsbedingungen gelten ebenfalls -- zum Beispiel kann ein Token mit `project:read` nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6. Erfrische den Token

Wenn der Zugriffstoken abläuft, verwende den Refresh-Token, um einen neuen Token zu erhalten, ohne den Benutzer erneut durch den Einwilligungsfluss zu senden:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Widerrufe einen Token

Wenn ein Benutzer deine App deaktiviert oder du keinen Zugriff mehr benötigst, widerrufe den Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Auswahl von Scopes

Fordere nur die Scopes an, die deine Anwendung benötigt. Hier sind einige gängige Kombinationen:

| Anwendungsfall | Scopes |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Organisatorische Ressourcen verwalten | `user:read organization:read organization:write members:read members:write project:read project:write` |

Sehe dir die [Scopes-Referenz](/docs/reference/apis/authorization) für alle verfügbaren Scopes an.

## Discovery-Endpunkte

Deine Anwendung kann Glossias OAuth-Endpunkte automatisch entdecken, indem du die Server-Metadaten abholst:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Hiermit wird ein JSON-Dokument mit den `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` und weiteren Details zurückgegeben. Durch Verwendung von Discovery wird deine Integration gegenüber Änderungen der Endpunkte resilient.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer der Zustimmung verweigert oder während der Autorisierung etwas schiefgeht, leitet Glossia zu deiner Callback-URL mit einem `error`-Parameter weiter:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Gängige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | Die Anforderung fehlt einen erforderlichen Parameter |
| `invalid_scope` | Einer oder mehrere angeforderte Scopes sind ungültig |

### Tokenfehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerkörper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratelimit

OAuth-Endpunkte werden pro IP address begrenzt. Wenn du den Limit erreichst, erhältst du HTTP 429. Siehe die [Rate Limiting-Referenz](/docs/reference/apis/authentication) für Details.

## Security-Checkliste

Bevor du in die Produktion gehst, verificiere, dass deine Implementierung diese Praktiken befolgt:

- Verwende in der Production immer HTTPS für Callback-URLs
- Validiere den `state`-Parameter im Callback, um CSRF zu verhindern
- Speichere Tokens verschlüsselt im Ruhezustand
- Mach niemals Tokens in clientseitigem JavaScript oder Browser-URLs öffentlich
- Verwende nur die minimal benötigten Scopes.
- Behandle Token-Abläufe sanft mit Refresh-Tokens.
- Widerrufe Tokens, wenn Benutzer deine App deaktivieren oder ihr Konto löschen.
