%{
  title: "Mit Glossia anmelden",
  summary:
    "Ermöglichen Sie Benutzern, sich mit ihrem Glossia-Konto mittels OAuth 2.1 in Ihre App einzuloggen.",
  category: "Anleitung",
  order: 2
}
---
Diese Anleitung führt Sie durch das Hinzufügen von "Anmeldung mit Glossia" zu Ihrer Anwendung. Bis zum Ende können Ihre Benutzer sich mit ihrem Glossia-Konto anmelden und Ihre App verfügt über ein Zugriffstoken, um die Glossia-API im Namen der Benutzer aufzurufen.

Glossia verwendet **OAuth 2.1 mit PKCE** (Beweisschlüssel für Code-Austausch). PKCE ist für alle Clients erforderlich, einschließlich serverseitiger Anwendungen.

## 1\. Registrieren Sie Ihre OAuth-Anwendung

Sie haben zwei Optionen zur Registrierung Ihrer Anwendung:

### Option A: Über das Dashboard (empfohlen)

1. Melden Sie sich bei Glossia an und gehen Sie zu Ihrem Kontodashboard.
2. Öffnen Sie die **API** Bereich in der Seitenleiste und klicken **OAuth-Apps**.
3. Klicken **Neue Anwendung**.
4. Geben Sie den Anwendungs **Name** und **Callback-URL** (auch Umleit-URI genannt.).
5. Klicken Sie **Anwendung erstellen**.

Nach der Erstellung notieren Sie die **Client-ID** und **Clientgeheimnis**. Das Geheimnis wird nur einmal angezeigt, speichern Sie es daher sicher.

### Option B: Dynamische Clientregistrierung

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

Bevor Sie den Benutzer weiterleiten, generieren Sie einen PKCE-Code-Verifizierer und eine PKCE-Code-Challenge:

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
| `redirect_uri` | Ja | Muss mit einer registrierten Callback-URL übereinstimmen |
| `code_challenge` | Ja | Die PKCE-Code-Challenge (S256) |
| `code_challenge_method` | Ja | Immer `S256` |
| `scope` | Nr. | durch Leerzeichen getrennte Liste von [Bereiche](/docs/reference/apis/authentication).| Wenn nicht angegeben, wird minimaler Zugriff genutzt |
| `state` | Empfohlen | Eine zufällige Zeichenkette zur Verhinderung von CSRF-Angriffen. Überprüfen Sie, ob sie übereinstimmt, wenn der Benutzer zurückkehrt |

Der Benutzer wird einen Einwilligungsbildschirm sehen, der den Namen Ihrer Anwendung und die angeforderten Bereiche anzeigt. Nach Freigabe leitet Glossia an Ihre Callback-URL zurück und übermittelt einen Autorisierungscode.

## 4\. Tauschen Sie den Code gegen Tokens ein

Wenn der Benutzer an Ihre Callback-URL zurückgeleitet wird, enthält die URL `code` Parameter:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Zuerst, überprüfen Sie, dass `state` es entspricht dem, was Sie in Schritt 3 gesendet haben. Tauschen Sie dann den Code gegen Tokens ein:

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

Bewahren Sie beide Tokens sicher auf. Das Access-Token wird für API-Anfragen verwendet. Das Refresh-Token wird verwendet, um ein neues Access-Token zu erhalten, wenn das aktuelle abläuft.

## 5\. Rufen Sie die API im Namen des Benutzers auf

Verwenden Sie das Access-Token für authentifizierte API-Anfragen:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Die Scopes des Tokens begrenzen die Endpunkte, die Sie erreichen können. Die Autorisierung auf Ressourcenebene gilt nach wie vor - zum Beispiel ein Token mit `project:read` nur Projekte lesen kann, auf die der Benutzer Zugriff hat.

## 6\. Token aktualisieren

Wenn das Access-Token abläuft, verwenden Sie das Refresh-Token, um ein neues Token zu erhalten, ohne den Benutzer erneut durch den Einwilligungsablauf zu schicken:

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
| Vollständiger Zugriff auf die Organisation | `user:read organization:read organization:write members:read members:write project:read project:write` |

Sehen Sie die [Referenz für alle Bereiche](/docs/reference/apis/authentication) für alle verfügbaren Berechtigungsrahmen.

## Entdeckungs-Endpoints

Ihre Anwendung kann die OAuth-Endpunkte von Glossia automatisch entdecken, indem Sie die Server-Metadaten abrufen:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Dies gibt ein JSON-Dokument mit dem zurück. `authorization_endpoint`Die neu zusammengeführten Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Text-Literalen muss ein JSON-String-Array der gleichen Länge zurückgeben `token_endpoint`, `revocation_endpoint`Wir haben insgesamt 574 Dateien mit zusätzlichen Details gefunden. Entdeckung macht Ihre Integration widerstandsfähig gegenüber Änderungen der Endpunkte.

## Fehlerbehandlung

### Autorisierungsfehler

Wenn der Benutzer der Zustimmung widerspricht oder während der Autorisierung etwas schief geht, leitet Glossia an Ihre Callback-URL mit einem `error` Parameter:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Häufige Fehlercodes:

| Fehler | Bedeutung |
|-------|---------|
| `access_denied` | Der Benutzer hat die Autorisierung verweigert |
| `invalid_request` | In der Anfrage fehlt ein erforderlicher Parameter |
| `invalid_scope` | Ein oder mehrere angeforderte Bereiche sind ungültig |

### Tokenfehler

Der Token-Endpunkt gibt HTTP 400 mit einem JSON-Fehlerkörper zurück:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Ratenlimits

OAuth-Endpunkte sind pro IP rate limitiert. Wenn Sie das Limit erreichen, erhalten Sie HTTP 429. Siehe die [Referenz für Rate Limiting](/docs/reference/apis/authentication) für Details.

## Sicherheitscheckliste

Bevor Sie in die Produktion gehen, prüfen Sie, dass Ihre Implementierung diese Praktiken einhält:

- Verwenden Sie HTTPS immer für Callback-URLs in der Produktion
- Validieren Sie den `state` Parameter im Callback zur Verhinderung von CSRF
- Speichern Sie Token verschlüsselt im Ruhezustand
- Legen Sie Token niemals in clientseitigem JavaScript oder Browser-URLs offen.
- Verwenden Sie nur das notwendige Minimum an Scopes.
- Verwalten Sie Token-Abläufe angemessen mit Refresh-Tokens.
- Entziehen Sie Token, wenn Nutzer sich abmelden oder ihr Konto löschen.