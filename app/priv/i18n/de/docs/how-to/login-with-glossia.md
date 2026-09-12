%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglichen Sie Nutzern die Anmeldung bei Ihrer App mit ihrem Glossia-Konto über OAuth 2.1.",
  category: "Anleitungen",
  order: 2
}
---
Diese Anleitung führt Sie durch das Hinzufügen von "Login mit Glossia" zu Ihrer Anwendung. Bis zum Ende können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden und Ihre App verfügt über einen Zugriffstoken, um die Glossia-API im Namen der Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Proof Key for Code Exchange). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen zur Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und navigieren Sie zu Ihrem Konto-Dashboard.
2. Öffnen Sie die **API** Sektion in der Seitenleiste und klicken Sie **OAuth-Anwendungen**.
3. Klicken Sie **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch als Redirect URI bezeichnet).
5. Klicken Sie **Anwendung erstellen**.

Nach der Erstellung, beachten Sie das **Client-ID** und **Client-Secret**. Das Secret wird einmal angezeigt, speichern Sie es daher sicher.

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

Bevor der Benutzer umgeleitet wird, generiere einen PKCE-Code-Verifier und eine Code-Challenge:

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

## 3\. Leiten Sie den Benutzer zu Glossia um.

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
| `client_id` | Ja | Ihre Client-ID der Anwendung |
| `redirect_uri` | Ja | Muss einer registrierten Callback-URL entsprechen |
| `code_challenge` | Ja | Der PKCE Code Challenge (S256) |
| `code_challenge_method` | Ja | Immer | `S256` |
| `scope` | Nr. | Leerzeichengetrennte Liste von [Bereiche](/docs/reference/apis/authentication). Standardmäßig minimale Zugriffsrechte, wenn nicht angegeben |
| `state` | Empfohlen | Eine zufällige Zeichenkette, um CSRF-Angriffe zu verhindern. Überprüfen Sie, ob sie übereinstimmt, wenn der Benutzer zurückkehrt |

Der Nutzer wird einen Einverständnisscreen sehen, der den Namen Ihrer Anwendung und die angeforderten Bereiche anzeigt. Nach Genehmigung leitet Glossia auf Ihre callback URL um und übermittelt einen Autorisierungscode.

## 4\. Code gegen Tokens eintauschen

Wenn der Benutzer zurück zu Ihrer callback URL umgeleitet wird, enthält die URL einen `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Zuerst überprüfen Sie, dass `state` es mit dem übereinstimmt, was Sie in Schritt 3 gesendet haben. Tauschen Sie dann den Code gegen Tokens ein:

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

Speichere beide Tokens sicher. Der AccessToken wird für API-Anfragen verwendet. Der Refresh-Token wird verwendet, um einen neuen AccessToken zu erhalten, wenn der aktuelle abgelaufen ist.

## 5\. Ruft die API im Namen des Benutzers auf

Verwende den AccessToken, um authentifizierte API-Anfragen zu stellen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen, welche Endpunkte du zugreifen kannst. Die Ressourcensebene-Autorisierung gilt weiterhin - beispielsweise ein Token, der `project:read` kann nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6\. Aktualisiere den Token

Wenn der AccessToken abgelaufen ist, verwende den Refresh-Token, um einen neuen Token zu erhalten, ohne den Benutzer erneut durch den Einwilligungsfluss zu führen:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Token widerrufen

Wenn sich ein Nutzer von Ihrer App trennt oder Sie den Zugriff nicht mehr benötigen, widerrufen Sie das Token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Berechtigungen auswählen

Fordern Sie nur die für Ihre Anwendung benötigten Berechtigungen an. Hier sind einige gängige Kombinationen:

| Verwendungszweck | Berechtigungen |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte lesen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Vollständiger Organisationszugriff | `user:read organization:read organization:write members:read members:write project:read project:write` |

Siehe die [Vollständige Bereiche-Referenz](/docs/reference/apis/authentication) für alle verfügbaren Bereiche.

## Entdeckungs-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem sie die Servermetadaten abruft:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies liefert ein JSON-Dokument mit dem `authorization_endpoint`Das neuassembled Dokument hat die Validierung zuvor nicht bestanden: Die Wiederherstellung von Markdown-Textknoten ergab eine leere Übersetzung `token_endpoint`Das neu zusammengesetzte Dokument hat die Validierung zuvor nicht bestanden: Die Wiederherstellung von Markdown-Textknoten erzeugte eine leere Übersetzung `revocation_endpoint`, und weitere Details. Die Nutzung von Discovery macht die Integration robust gegenüber Änderungen der Endpunkte.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer der Zustimmung verweigert oder bei der Autorisierung etwas schiefgeht, leitet Glossia zur Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Typische Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | In der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Eine oder mehrere angeforderte Bereiche sind ungültig |

### Tokenfehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerinhalt zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenlimits

OAuth-Endpunkte sind pro IP limitiert. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Sehen Sie den [Referenz zur Rate Limiting](/docs/reference/apis/authentication) für weitere Details.

## Sicherheits-Checkliste

Bevor Sie in die Produktion gehen, überprüfen Sie, dass Ihre Implementierung diese Praktiken einhält:

- Verwenden Sie immer HTTPS für Callback-URLs in der Produktion
- Validieren Sie den `state` Parameter im Callback, um CSRF zu verhindern
- Speichern Sie Tokens verschlüsselt im Ruhezustand
- Veröffentlichen Sie niemals Tokens in clientseitigem JavaScript oder Browser-URLs
- Verwenden Sie das Minimum an benötigten Scopes
- Verarbeiten Sie Token-Abläufe sanft mittels Refresh-Tokens
- Entziehen Sie Tokens, wenn sich Benutzer abmelden oder ihr Konto löschen