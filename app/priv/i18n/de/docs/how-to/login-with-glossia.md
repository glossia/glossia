%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglichen Sie Benutzern die Anmeldung in Ihrer App mit ihrem Glossia-Konto über OAuth 2.1.",
  category: "Anleitung",
  section: "platform",
  order: 2
}
---
Dieser Leitfaden führt Sie durch das Hinzufügen von "Einloggen mit Glossia" zu Ihrer Anwendung. Nach Abschluss dieses Leitfadens können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden und Ihre App wird über einen Zugriffstoken verfügen, um die Glossia-API im Namen ihrer Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Beweisschlüssel für Code-Austausch). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen zur Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Kontodashboard.
2. Öffnen Sie die **API** Sektion in der Seitenleiste und klicken Sie auf **OAuth-Anwendungen**.
3. Klicken Sie auf **Neue Anwendung**.
4. Geben Sie die Anwendung **Name** und **Callback-URL** (auch als Redirect-URI genannt).
5. Klicken **Anwendung erstellen**.

Nach der Erstellung, notieren Sie sich die **Client-ID** und **Client-Secret**. Das Client-Secret wird nur einmal angezeigt, speichern Sie es daher sicher.

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

## 2\. Generiere eine PKCE Code-Challenge

Bevor der Benutzer umgeleitet wird, generiere einen PKCE Code-Verifizierer und eine Code-Challenge:

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

## 3\. Leite den Benutzer zu Glossia um

Erstelle die Autorisierungs-URL und leite den Browser des Benutzers um:

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
| `code_challenge` | Ja | Der PKCE Code Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nr. | Leerzeichengetrennte Liste von [Bereiche](/docs/reference/apis/authorization). Keine Aktionsbereiche werden gewährt, wenn nicht angegeben |
| `state` | Empfohlen | Eine zufällige Zeichenkette, um CSRF-Angriffe zu verhindern. Überprüfen Sie, ob es übereinstimmt, wenn der Benutzer zurückkehrt. |

Der Benutzer sieht einen Einverständnisschirm, der Ihren Anwendungsname und die angeforderten Bereiche anzeigt. Nach der Genehmigung leitet Glossia zu Ihrer Callback-URL weiter und übermittelt einen Autorisierungscode.

## 4\. Tauschen Sie den Code gegen Tokens ein

Wenn der Benutzer zu Ihrer Callback-URL zurückgeleitet wird, enthält die URL einen `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Zuerst prüfen Sie, dass `state` es entspricht dem, was Sie in Schritt 3 gesendet haben. Tauschen Sie anschließend den Code gegen Tokens ein:

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

Speichere beide Tokens sicher. Das Zugriffstoken wird für API-Anfragen verwendet. Das Refresh-Token wird verwendet, um ein neues Zugriffstoken zu erhalten, wenn das aktuelle abläuft.

## 5\. Rufen Sie die API im Namen des Benutzers auf

Verwenden Sie das Zugriffstoken für authentifizierte API-Anfragen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen, auf welche Endpunkte Sie zugreifen können. Die Autorisierung auf Ressourcensebene gilt weiterhin -- beispielsweise ein Token mit `project:read` kann nur Projekte lesen, auf die der Benutzer Zugriff hat.

## 6\. Refreshen Sie den Token

Wenn das Zugriffstoken abläuft, verwenden Sie das Refresh-Token, um ein neues zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf schicken zu müssen.

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

Fordern Sie nur die Bereiche an, die Ihre Anwendung benötigt. Hier sind einige gängige Kombinationen:

| Anwendungszweck | Bereiche |
|----------|--------|
| Benutzerprofil lesen | `user:read` |
| Projekte und Inhalte einsehen | `user:read project:read voice:read` |
| Projekte verwalten | `user:read project:read project:write` |
| Organisationsressourcen verwalten | `user:read organization:read organization:write members:read members:write project:read project:write` |

Siehe die [Bereiche-Referenz](/docs/reference/apis/authorization) für alle verfügbaren Bereiche.

## Discovery-Endpunkte

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem Sie die Server-Metadaten abrufen:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument mit dem `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, weitere Details. Die Verwendung von Discovery macht Ihre Integration robust gegenüber Änderungen der Endpunkte.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Nutzer die Einwilligung verweigert oder während der Autorisierung etwas schiefgeht, leitet Glossia an Ihre Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Nutzer hat die Autorisierungsanfrage abgelehnt |
| `invalid_request` | An der Anforderung fehlt ein erforderlicher Parameter |
| `invalid_scope` | Ein oder mehrere angeforderte Scope sind ungültig |

### Tokenfehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerkörper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenbegrenzungen

OAuth-Endpunkte unterliegen einer Ratenlimitierung pro IP-Adresse. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Sehen Sie die [Referenz zur Rate Limitierung](/docs/reference/apis/authentication) für weitere Details.

## Sicherheits-Checkliste

Bevor Sie in die Produktion gehen, überprüfen Sie, dass Ihre Implementierung diesen Praktiken folgt:

- Verwenden Sie immer HTTPS für Callback-URLs in der Produktion
- Validieren Sie den `state` Parameter im Callback, um CSRF zu verhindern
- Speichern Sie Tokens verschlüsselt im Ruhezustand
- Legen Sie Tokens niemals in clientseitigem JavaScript oder Browser-URLs offen.
- Nutzen Sie die minimale Menge an benötigten Scopes.
- Verwalten Sie den Token-Ablauf nahtlos mit Refresh-Tokens.
- Entziehen Sie Tokens, wenn Benutzer sich abmelden oder ihr Konto löschen.