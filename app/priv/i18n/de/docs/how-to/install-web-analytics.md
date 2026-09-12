%{
  title: "Webanalyse installieren",
  summary:
    "Fügen Sie das Glossia Web-SDK mit einer Zeile HTML oder über npm an Ihrer Website hinzu und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  order: 1
}
---
Dieser Leitfaden geht davon aus, dass Sie ein Glossia-Projekt haben, in dem dessen Website-Domain in den Analytics-Einstellungen des Projekts konfiguriert ist. Die Sammlung wird durch diese Domain identifiziert, sodass Sie keinen Schlüssel oder kein Geheimnis kopieren müssen.

## Option A: Script-Tag

Fügen Sie diesen Ausschnitt idealerweise auf jeder Seite in das `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet eine Pageview beim Laden und erfasst nachfolgende Pageviews bei der Client-seitigen Navigation in Single-Page-Apps. `data-domain` standardmäßig auf `window.location.hostname` wenn weggelassen, sodass Sie es auf einer Single-Domain-Webseite auslassen können. Um einen benutzerdefinierten Collection-Endpoint zu verwenden, fügen `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Installiere das Paket:

```bash
npm install @glossia/web
```

Initialisiere es einmal im Startpunkt deiner Anwendung:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Das `domain` wird abgeleitet von `window.location.hostname` damit das SDK dem für deine Website registrierten Projekt zugewiesen wird. Übergib `{ domain: "example.com" }` um dies zu überschreiben, z. B. um Ereignisse von einem Staging-Origin an das gleiche Projekt wie in der Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu erfassen, z. B. eine Registrierung:

```ts
glossia.track("signup");
```

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Website im Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie eine `POST` Anfrage zu `/api/analytics/events` zurückgibt `202 Accepted`.
3. Innerhalb einer Minute erscheint der Pageview im Analytics-Dashboard Ihres Projekts.

## Was gesammelt wird

Der Browser sendet die Seiten-URL, den Referrer, `navigator.languages`, die Zeitzone und die Bildschirmbreite sowie eine pro-Tab-Sitzungs-ID. Der Server fügt das Land hinzu (via GeoIP) und berechnet die Lokalisierungslücke im Vergleich zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und es erfolgt kein Fingerprinting.