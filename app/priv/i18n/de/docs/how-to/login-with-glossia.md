%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglicht Benutzern, sich in Ihrer App mit ihrem Glossia-Konto über OAuth 2.1 anzumelden.",
  category: "Anleitung",
  order: 2
}
---
Dieser Leitfaden führt Sie durch das Hinzufügen von "Login mit Glossia" in Ihre Anwendung. Bis zum Ende können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden, und Ihre App verfügt über einen Zugriffstoken, um die Glossia-API im Namen ihrer Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Schlüssel zum Codeaustausch). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen, um Ihre Anwendung zu registrieren:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Kontodashboard.
2. Öffnen Sie die **API** Sektion in der Sidebar und klicken **OAuth-Anwendungen**.
3. Klicken Sie **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch als Umleitungs-URI bezeichnet).
5. Klicken **Anwendung erstellen**.

Nach der Erstellung merke dir die **Client ID** und **Client secret**. Das Geheimnis wird nur einmal angezeigt, speichere es daher sicher.

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

## 2\. Generieren Sie einen PKCE-Code-Challenge

Bevor Sie den Benutzer umleiten, erstellen Sie einen PKCE-Code-Verifikator und eine Code-Challenge:

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

Erstellen Sie die Autorisierungs-URL und leiten Sie den Webbrowser des Benutzers weiter:

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
| `code_challenge` | Ja | Die PKCE Code Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nr. | Leerzeichengetrennte Liste von [Bereiche](/docs/reference/apis/authentication). Standardmäßig minimaler Zugriff, falls nicht angegeben |
| `state` | Empfohlen | Eine zufällige Zeichenfolge, um CSRF-Angriffe zu verhindern. Stellen Sie sicher, dass sie übereinstimmt, wenn der Benutzer zurückkehrt |

Der Benutzer sieht einen Einwilligungs-Bildschirm, der den Namen Ihrer Anwendung und die angeforderten Bereiche anzeigt. Nach der Zustimmung leitet Glossia zurück zu Ihrer callback URL mit einem Autorisierungscode.

## 4\. Tauschen Sie den Code gegen Token ein

Wenn der Benutzer an Ihre callback URL weitergeleitet wird, enthält die URL einen `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Prüfen Sie zunächst, dass `state` entspricht dem, was Sie in Schritt 3 gesendet haben. Tauschen Sie dann den Code gegen Tokens ein:

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

Speichere beide Tokens sicher. Das Zugriffstoken wird für API-Anfragen verwendet. Das Refresh-Token wird genutzt, um ein neues Zugriffstoken zu erhalten, wenn das aktuelle abläuft.

## 5\. Rufe die API im Namen des Benutzers auf

Verwende das Zugriffstoken, um authentizierte API-Anfragen durchzuführen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen, auf welche Endpunkte du zugreifen kannst. Die Autorisierung auf Ressourcenebene gilt weiterhin - beispielsweise einem Token mit `project:read` kann nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6\. Aktualisiere das Token

Wenn das Zugriffstoken abläuft, verwende das Refresh-Token, um ein neues zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf senden zu müssen:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Token widerrufen

Wenn ein Benutzer Ihre App trennt oder Sie keinen Zugriff mehr benötigen, widerrufen Sie das Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Bereiche auswählen

Fordern Sie nur die Bereiche an, die Ihre Anwendung benötigt. Hier sind einige gängige Kombinationen:

| Anwendungsfälle | Bereiche |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Vollständiger Organisationszugriff | `user:read organization:read organization:write members:read members:write project:read project:write` |

Sehen Sie die [volle Berechtigungsreferenz](/docs/reference/apis/authentication) “für alle verfügbaren Bereiche.”

## “Entdeckungs-Endpunkte”

“Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem Sie die Server-Metadaten abrufen:”

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

“Dies gibt ein JSON-Dokument mit dem” `authorization_endpoint`“,” `token_endpoint`“,” `revocation_endpoint`“, und andere Details. Die Verwendung der Entdeckung macht Ihre Integration robust gegenüber Änderungen der Endpunkte.”

## “Fehlerbehandlung”

### Autorisierungsfehler

Falls der Benutzer der Einwilligung nicht zustimmt oder etwas schiefgeht während der Autorisierung, leitet Glossia Ihre Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Allgemeine Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | Es fehlt ein erforderlicher Parameter in der Anfrage |
| `invalid_scope` | Eine oder mehrere angeforderte Scopes sind ungültig |

### Token-Fehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerinhalt zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Nutzungslimits

OAuth-Endpunkte sind pro IP limitiert. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Siehe [Rate Limiting Referenz](/docs/reference/apis/authentication) für Details.

## Sicherheits-Checkliste

Bevor Sie in die Produktion gehen, überprüfen Sie, dass Ihre Implementierung diese Praktiken einhält:

- Verwenden Sie HTTPS immer für Callback-URLs in der Produktion
- Validieren Sie den `state` Parameter am Callback zur Vermeidung von CSRF
- Speichern Sie Tokens verschlüsselt im Ruhezustand
- Legen Sie Tokens niemals in clientseitigem JavaScript oder Browser-URLs offen.
- Verwenden Sie nur die minimal notwendigen Scopes.
- Verwalten Sie Token-Abläufe reibungslos mit Refresh-Tokens.
- Widerrufen Sie Tokens, wenn Nutzer sich abmelden oder ihr Konto löschen.