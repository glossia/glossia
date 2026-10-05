%{
  title: "Web-Analytik installieren",
  summary:
    "Fügen Sie das Glossia Web SDK mit einer HTML-Zeile oder über npm in Ihre Webseite ein und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  section: "analytics",
  order: 1
}
---
Diese Anleitung geht davon aus, dass Sie ein Glossia-Projekt besitzen, dessen Site-Domain in den Analyse-Einstellungen des Projekts konfiguriert ist. Die Kollektion wird durch diese Domain identifiziert, sodass Sie keinen Schlüssel oder Geheimnis kopieren müssen.

## Option A: Script-Tag

Fügen Sie dieses Snippet auf jede Seite hinzu, idealerweise in der `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Das SDK initialisiert automatisch, sendet einen Pageview beim Laden und erfasst nachfolgende Pageviews bei clientseitiger Navigation in Single-Page-Apps. `data-domain` standardmäßig auf `window.location.hostname` wenn nicht angegeben, können Sie es auf einer Single-Domain-Webseite platzieren. Um einen benutzerdefinierten Kollektions-Endpunkt zu verwenden, fügen Sie hinzu `data-endpoint="https://collect.your-host.com"`.

Wenn Ihre Website eine Content-Security-Policy verwendet, erlauben `https://glossia.ai` in beiden `script-src` (oder `script-src-elem` wenn vorhanden) und `connect-src`. Das Skript lädt von `/assets/glossia-web.js` und sendet Ereignisse an `/v1/collect` auf demselben Ursprung.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal am Einstiegspunkt Ihrer Anwendung:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Stellen Sie den Sammlungsendpunkt explizit ein, wenn Sie das Paket in Ihrem eigenen Bundle verwenden, da es keine gehostete Skriptadresse gibt, aus der diese abgeleitet werden könnte.

`domain` wird aus `window.location.hostname` damit das SDK für das für Ihre Website registrierte Projekt erfasst. Geben Sie `{ domain: "example.com" }` um dies zu überschreiben, beispielsweise um Ereignisse von einem Staging-Ursprung an dasselbe Projekt wie in der Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu erfassen, beispielsweise eine Registrierung:

```ts
glossia.track("signup");
```

## Verifizieren Sie Ihre Domain

In Ihrem Projekt **Analyse-Einstellungen**, speichern Sie Ihre Domain. Die **Domainbesitz verifizieren** Karte zeigt den genauen Eintragnamen und Wert für Ihr Projekt. Fügen Sie einen Texteintrag bei Ihrem Domainanbieter hinzu:

| Feld | Wert |
| --- | --- |
| Typ | `TXT` ([Texteintrag](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Wert | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Verwenden Sie die Domäne und den Token, die in Ihren Einstellungen angezeigt werden. Einige Anbieter fügen die Domäne automatisch hinzu; in diesem Fall geben Sie nur ein. `_glossia-verify` wie im Namen. Nach dem Veröffentlichen der Eintragung, klicken **Domain verifizieren**. Änderungen können einige Zeit benötigen, um verfügbar zu sein. Bitte versuchen Sie es erneut, falls die Eintragung nicht sofort gefunden wird.

Wenn Sie Ihre Domain-Einträge nicht bearbeiten können, erweitern **Alternative: Verifizierung über ein Meta-Tag der Startseite**Kopieren Sie das generierte Tag in das `<head>` Ihrer Startseite und veröffentlichen Sie diese:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Beide Methoden beweisen die Kontrolle über die konfigurierte Domain. Glossia prüft die Eintragung dieser Domain oder deren Startseite, so dass das Kopieren des Tokens auf eine andere Website den Besitz nicht verifiziert. Das Token ist ein öffentlicher Nachweis, kein Passwort.

Sobald die Domain verifiziert ist, zeichnet Glossia Ereignisse aus Ihrem Tracking-Snippet auf. Das Snippet allein verifiziert die Eigentümerschaft nicht. Eine Änderung der konfigurierten Domain erfordert erneut eine Verifizierung.

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Seite im Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie eine `POST` Anfrage an `https://glossia.ai/v1/collect` zurückgibt `202 Accepted`.
3. Nach Erfassung und Verarbeitung erscheint der Seitenaufruf unter **Analytics** in Ihrem Projektdashboard. Übersetzungsläufe auf der Übersichtsseite sind vom Website-Traffic getrennt.

Eine `202 Accepted` Antwort bestätigt, dass die Anforderung den Kollektor erreicht hat. Unbekannte oder nicht verifizierte Domains werden ebenfalls akzeptiert, protokollieren aber keine Ereignisse. Stellen Sie sicher, dass die konfigurierte Domain in den Analytics-Einstellungen des Projekts verifiziert ist.

## Was wird gesammelt

Der Browser sendet die Seiten-URL, den Referrer, `navigator.languages`Zeitzone, und Bildschirmbreite, sowie eine pro-Tab-Sitzungs-ID. Der Server fügt das Land (via GeoIP) hinzu und berechnet die Lokalisierungslücke gegenüber den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und keine Fingerabdrücke erstellt.