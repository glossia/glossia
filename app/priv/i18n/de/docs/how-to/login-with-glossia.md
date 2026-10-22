%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglicht Benutzern die Anmeldung in Ihrer App mit ihrem Glossia-Konto über OAuth 2.1.",
  category: "Anleitung",
  section: "platform",
  order: 2
}
---

Dieser Leitfaden führt Sie durch die Hinzufügung von "Einloggen mit Glossia" zu Ihrer Anwendung. Bis zum Ende können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden und Ihre App wird ein Zugriffstoken haben, um die Glossia-API im Namen der Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen zur Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Account-Dashboard.
2. Öffnen Sie den **API**-Bereich in der Seitenleiste und klicken Sie auf **OAuth-Anwendungen**.
3. Klicken Sie auf **Neue Anwendung**.
4. Geben Sie den **Name** der Anwendung und den **Callback URL** (auch als Redirect-URI bezeichnet) ein.
5. Klicken Sie auf **Anwendung erstellen**.

Nach der Erstellung notieren Sie sich das **Client-ID** und das **Client-Schlüssel**. Das Geheimnis wird nur einmal angezeigt, sodass Sie es sicher speichern.

### Option B: Dynamische Registrierung von Clients

Senden Sie eine `POST`-Anforderung an `/oauth/register`:

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

Bevor Sie den Benutzer umleiten, generieren Sie einen PKCE-Code-Verifizierer und eine Herausforderung:

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

**Parameter:**

| Parameter | Erforderlich | Beschreibung |
|-----------|----------|-------------|
| `response_type` | Ja | Immer `code` |
| `client_id` | Ja | Die Client-ID Ihrer Anwendung |
| `redirect_uri` | Ja | Muss einer registrierten Callback-URL entsprechen |
| `code_challenge` | Ja | Die PKCE-Code-Herausforderung (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nein | Raumgetrennte Liste von [Berechtigungen](/docs/reference/apis/authorization). Keine Aktionsberechtigungen werden erteilt, wenn nicht angegeben |
| `state` | Empfohlen | Eine zufällige Zeichenkette zur Verhinderung von CSRF-Angriffen. Überprüfen Sie die Übereinstimmung, wenn der Benutzer zurückkehrt |

Der Benutzer sieht einen Einwilligungsbildschirm, der Ihren Anwendungsname und die angeforderten Berechtigungen anzeigt. Nach Genehmigung leitet Glossia zurück zu Ihrer Callback-URL mit einem Autorisierungscode.

## 4. Tauschen Sie den Code gegen Token ein

Wenn der Benutzer zur Callback-URL zurückgeleitet wird, enthält die URL einen `code`-Parameter:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Zuerst, prüfen Sie, ob `state` dem entspricht, was Sie in Schritt 3 gesendet haben. Tauschen Sie dann den Code gegen Token ein:

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

Speichern Sie beide Token sicher. Das Access-Token wird für API-Anfragen verwendet. Das Refresh-Token wird verwendet, um ein neues Access-Token zu erhalten, wenn das aktuelle abläuft.

## 5. Rufen Sie die API im Namen des Benutzers auf

Verwenden Sie das Access-Token, um authentisierte API-Anfragen durchzuführen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Berechtigungen des Tokens begrenzen, auf welche Endpunkte Sie zugreifen können. Die nach Ressourcenstufen ausgerichtete Autorisierung gilt weiterhin – beispielsweise kann ein Token mit `project:read` nur die Projekte lesen, auf die der Benutzer Zugriff hat.

## 6. Erweitern Sie das Token

Wenn das Access-Token abläuft, verwenden Sie das Refresh-Token, um ein neues Token zu erhalten, ohne den Benutzer erneut durch den Einwilligungsfluss zu senden:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Widerrufen Sie ein Token

Wenn ein Benutzer Ihre App löst oder Sie keinen Zugriff mehr benötigen, widerrufen Sie das Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Berechtigungen auswählen

Fordern Sie nur die Berechtigungen an, die Ihre Anwendung benötigt. Hier sind einige gängige Kombinationen:

| Anwendungsbereich | Berechtigungen |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalt lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Organisationsressourcen verwalten | `user:read organization:read organization:write members:read members:write project:read project:write` |

Siehe die [Berechtigungs-Referenz](/docs/reference/apis/authorization) für alle verfügbaren Berechtigungen.

## Discovery-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem Sie die Server-Metadaten abrufen:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument mit dem `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` und anderem zurück. Die Verwendung der Discoverbarkeit macht Ihre Integration widerstandsfähig gegenüber Änderungen an den Endpunkten.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer der Einwilligung widersagt oder etwas während der Autorisierung schiefgeht, leitet Glossia zu Ihrer Callback-URL mit einem `error`-Parameter weiter:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Gängige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierung abgelehnt |
| `invalid_request` | Die Anforderung fehlt einen erforderlichen Parameter |
| `invalid_scope` | Eine oder mehrere angeforderte Berechtigungen sind ungültig |

### Token-Fehler

Das Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerkörper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenlimits

OAuth-Endpunkte werden pro IP-Rate limit. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Weitere Informationen finden Sie in der [Referenz zur Rate Limiting](/docs/reference/apis/authentication).

## Sicherheits-Checkliste

Bevor Sie in die Produktion gehen, überprüfen Sie, dass Ihre Implementierung diese Praktiken befolgt:

- Verwenden Sie immer HTTPS für Callback-URLs in der Produktion
- Validieren Sie den `state`-Parameter an der Rückseite, um CSRF-Angriffe zu verhindern
- Speichern Sie Token verschlüsselt im Ruhezustand
- Weisen Sie Token in clientseitigen JavaScript oder Browser-URLs niemals aus
- Verwenden Sie nur die minimal benötigten Berechtigungen
- Verwalten Sie Token-Abläufe sanft mit Refresh-Tokens
- Widerrufen Sie Tokens, wenn Benutzer Ihre App lösen oder ihr Konto löschen
