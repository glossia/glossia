%{
  title: "Webanalyse installieren",
  summary:
    "Fügen Sie das Glossia Web-SDK mit einer einzigen HTML-Zeile oder über npm hinzu und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitungen",
  order: 1
}
---
Diese Anleitung geht davon aus, dass Sie ein Glossia-Projekt haben, dessen Site-Domain in den Analysesiteinstellungen des Projekts konfiguriert ist. Die Sammlung wird durch diese Domain identifiziert, sodass Sie keinen Schlüssel oder ein Geheimnis kopieren müssen.

## Option A: Script-Tag

Fügen Sie diesen Code-Ausschnitt auf jeder Seite ein, idealerweise in der `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet eine Pageview beim Laden und erfasst nachfolgende Pageviews bei Client-seitiger Navigation in Single-Page-Apps. `data-domain` standardmäßig auf `window.location.hostname` wenn weggelassen, sodass Sie es auf einer Single-Domain-Site einsetzen können. Um einen benutzerdefinierten Erfassungs-Endpunkt zu verwenden, fügen Sie hinzu `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungseintritts-Punkt:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Das `domain` wird aus ... abgeleitet `window.location.hostname` so dass das SDK die Protokollierung dem für Ihre Website registrierten Projekt zuordnet. Geben Sie `{ domain: "example.com" }` um dies zu überschreiben, zum Beispiel um Ereignisse von einer Staging-Quelle an das gleiche Projekt wie die Produktion zu senden.

Um ein benutzerdefiniertes Ereignis aufzuzeichnen, z. B. eine Anmeldung:

```ts
glossia.track("signup");
```

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Seite im Browser.
2. Öffnen Sie den Netzwerkkasten und bestätigen Sie eine `POST` Anfrage an `/api/analytics/events` antwortet `202 Accepted`.
3. Innerhalb einer Minute erscheint die Seitenansicht im Analytics-Dashboard Ihres Projekts.

## Was wird gesammelt

Der Browser sendet die Seiten-URL, den Referrer, `navigator.languages`, Zeitzone und Bildschirmbreite, sowie eine pro-Tab-Sitzungs-ID. Der Server fügt das Land (aus GeoIP) hinzu und berechnet den Lokalisierungsabstand zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und nichts wird gefingerprinted.