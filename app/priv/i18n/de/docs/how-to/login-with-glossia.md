%{
  title: "Mit Glossia einloggen",
  summary:
    "Ermöglichen Sie Benutzern, sich mit ihrem Glossia-Konto über OAuth 2.1 in Ihre App einzuloggen.",
  category: "Anleitung",
  section: "Plattform",
  order: 2
}
---
Diese Anleitung führt Sie durch das Hinzufügen von "Anmelden mit Glossia" zu Ihrer Anwendung. Bis zum Ende können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden und Ihre Anwendung verfügt über ein Zugriffstoken, um die Glossia-API im Namen der Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Beweis-Schlüssel für Code-Austausch). PKCE ist für alle Clients erforderlich, einschließlich server-seitiger Anwendungen.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Es stehen Ihnen zwei Möglichkeiten zur Registrierung Ihrer Anwendung zur Verfügung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Kontodashboard.
2. Öffnen Sie den **API** Bereich in der Seitenleiste und klicken Sie auf **OAuth-Anwendungen**.
3. Klicken Sie auf **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch als Redirect-URI bezeichnet).
5. Klicken **Anwendung erstellen**.

Nach der Erstellung merke dir die **Client ID** und **Client secret**. Der geheime Schlüssel wird nur einmal angezeigt, daher solltest du ihn sicher speichern.

### Option B: Dynamische Client-Registrierung

Sende eine `POST` Anfrage an `/oauth/register`:

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

Generieren Sie vor der Weiterleitung des Benutzers einen PKCE-Code-Verifier und eine PKCE-Code-Challenge:

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
| `client_id` | Ja | Client-ID Ihrer Anwendung |
| `redirect_uri` | Ja | Muss einer registrierten Callback-URL entsprechen |
| `code_challenge` | Ja | Die PKCE-Code-Challenge (S256) |
| `code_challenge_method` | Ja | Immer | `S256` |
| `scope` | Hinweis | Leerzeichengetrennte Liste von [Scopes](/docs/reference/apis/authentication). Standardmäßig minimale Berechtigungen, wenn weggelassen |
| `state` | Empfohlen | Eine zufällige Zeichenfolge, um CSRF-Angriffe zu verhindern. Stellen Sie sicher, dass sie übereinstimmen, wenn der Benutzer zurückkehrt. |

Der Benutzer sieht einen Einwilligungs-Bildschirm, der Ihren Anwendungsname und die angeforderten Scopes anzeigt. Nach Genehmigung leitet Glossia zurück zu Ihrer Callback-URL mit einem Autorisierungscode.

## 4\. Tauschen Sie den Code gegen Token ein

Wenn der Benutzer zu Ihrer Callback-URL weitergeleitet wird, enthält die URL einen `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Zuerst prüfen Sie, dass `state` mit dem übereinstimmt, was Sie in Schritt 3 gesendet haben. Tauschen Sie dann den Code gegen Tokens aus:

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

Speichere beide Tokens sicher. Das Zugriffstoken wird für API-Anfragen verwendet. Das Refresh-Token wird verwendet, um ein neues Zugriffstoken zu erhalten, wenn das aktuelle Token abgelaufen ist.

## 5\. Rufe die API im Namen des Benutzers auf

Verwende das Zugriffstoken, um authentifizierte API-Anfragen zu stellen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Berechtigungen des Tokens begrenzen, welche Endpunkte du zugreifen kannst. Die Autorisierung auf Ressourcenebene gilt weiterhin - beispielsweise ein Token, der `project:read` kann nur auf Projekte lesen, auf die der Benutzer Zugriff hat.

## 6\. Aktualisiere das Token

Wenn das Zugriffstoken abläuft, verwende das Refresh-Token, um ein neues Token zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf zu leiten:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Ein Token widerrufen

Wenn ein Benutzer Ihre App trennt oder Sie keinen Zugriff mehr benötigen, widerrufen Sie das Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Bereiche auswählen

Anfordern Sie nur die Bereiche, die Ihre Anwendung benötigt. Hier sind einige gängige Kombinationen:

| Anwendungsfall | Bereiche |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Vollständiger Zugriff auf die Organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Sehen Sie die [Vollständige Referenz für Bereiche](/docs/reference/apis/authentication) für alle verfügbaren Bereiche.

## Discovery-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem sie die Server-Metadaten abruft:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument zurück mit dem `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, und weitere Details. Die Nutzung der Discovery macht Ihre Integration robust gegenüber Änderungen der Endpunkte.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer der Einwilligung widerspricht oder während der Autorisierung etwas schiefgeht, leitet Glossia Sie zu Ihrer Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | In der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Eine oder mehrere angeforderte Berechtigungen sind ungültig |

### Token-Fehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehler-Körper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenlimits

OAuth-Endpunkte sind pro IP-Adresse Rate-Limitiert. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Siehe [Referenz zur Rate Limiting](/docs/reference/apis/authentication) für Details.

## Sicherheits-Checkliste

Bevor Sie in die Produktion gehen, überprüfen Sie, dass Ihre Implementierung diese Praktiken einhält:

- Verwenden Sie immer HTTPS für Callback-URLs in der Produktion
- Validieren Sie den `state` Parameter auf dem Callback, um CSRF zu verhindern
- Speichern Sie Tokens verschlüsselt im Ruhezustand
- Geben Sie niemals Tokens in clientseitigem JavaScript oder Browser-URLs preis.
- Verwenden Sie die minimal benötigten Scopes.
- Verwalten Sie Token-Abläufe reibungslos mit Refresh-Tokens.
- Widerrufen Sie Tokens, wenn Benutzer ihre Verbindung trennen oder ihr Konto löschen.