%{
  title: "Webanalysen installieren",
  summary:
    "Fügen Sie das Glossia Web SDK Ihrer Website mit nur einer Zeile HTML oder via npm hinzu und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  order: 1
}
---
Diese Anleitung geht davon aus, dass Sie ein Glossia-Projekt besitzen, dessen Site-Domain in den Analyse-Einstellungen des Projekts konfiguriert ist. Die Collection wird durch diese Domain identifiziert, sodass kein Schlüssel oder Geheimcode kopiert werden muss.

## Option A: Script-Tag

Fügen Sie diesen Ausschnitt auf jeder Seite hinzu, idealerweise in der `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Die SDK initialisiert sich automatisch, sendet beim Laden eine Pageview und erfasst nachfolgende Pageviews bei der Navigation innerhalb von Single-Page-Apps. `data-domain` standardmäßig `window.location.hostname` wenn diese ausgelassen wird, sodass Sie diesen Knoten auf einer Single-Domain-Webseite verwenden können. Um auf einen benutzerdefinierten Collection-Endpoint zuzugreifen, fügen Sie `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Paket installieren:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal im Einstiegspunkt Ihrer Anwendung:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Der `domain` wird aus `window.location.hostname` so dass das SDK dem für Ihre Website registrierten Projekt zugeordnet wird. Geben Sie `{ domain: "example.com" }` zur Überschreibung, z.B. um Ereignisse von einer Staging-Quelle an dasselbe Projekt wie Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu erfassen, z.B. eine Registrierung:

```ts
glossia.track("signup");
```

## Prüfe, ob es funktioniert.

1. Öffne deine Seite im Browser.
2. Öffne den Netzwerk-Tab und bestätige eine `POST` Anfrage an `/api/analytics/events` antwortet `202 Accepted`.
3. Innerhalb einer Minute erscheint die Seitenansicht im Analytics-Dashboard deines Projekts.

## Was wird gesammelt

Der Browser sendet die Seiten-URL, den Referer, `navigator.languages`, Zeitzone und Bildschirmbreite, plus eine pro-Tab-Session-ID. Der Server fügt das Land (aus GeoIP) hinzu und berechnet den Lokalisierungsabstand zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und es wird kein Fingerprinting ausgeführt.