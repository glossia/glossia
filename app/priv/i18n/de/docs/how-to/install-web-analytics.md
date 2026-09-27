%{
  title: "Webanalytics installieren",
  summary:
    "Fügen Sie das Glossia Web-SDK Ihrer Seite mit einer einzigen Zeile HTML oder über npm hinzu und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  section: "Analytik",
  order: 1
}
---
Dieser Leitfaden geht davon aus, dass Sie ein Glossia-Projekt haben, dessen Site-Domain in den Analyseeinstellungen des Projekts konfiguriert ist. Die Sammlung wird durch diese Domain identifiziert, sodass kein Schlüssel oder Secret kopiert werden muss.

## Option A: Skript-Tag

Fügen Sie diesen Codeabschnitt zu jeder Seite hinzu, idealerweise im `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet eine Pageview beim Laden und zeichnet nachfolgende Pageviews bei der clientseitigen Navigation in Single-Page-Apps auf. `data-domain` standardmäßig auf `window.location.hostname` wenn nicht angegeben, können Sie es daher auf einer Single-Domain-Site verwenden. Um einen benutzerdefinierten Sammlung-Endpunkt zu nutzen, fügen Sie hinzu `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Paket installieren:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungseinstiegspunkt:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Das `domain` wird daraus abgeleitet `window.location.hostname` damit das SDK für das für Ihre Seite registrierte Projekt erfasst wird. Geben `{ domain: "example.com" }` um zu überschreiben, beispielsweise Ereignisse von einem Staging-Ursprung zum selben Projekt wie in Produktion zu senden.

Um ein benutzerdefiniertes Ereignis aufzuzeichnen, beispielsweise eine Registrierung:

```ts
glossia.track("signup");
```

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Website im Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie eine `POST` Anfrage an `/api/analytics/events` antwortet `202 Accepted`.
3. Innerhalb einer Minute erscheint der Seitenaufruf im Analytik-Dashboard Ihres Projekts.

## Was wird gesammelt

Der Browser sendet die Seiten-URL, den Referrer, `navigator.languages`Zeitzonen und Anzeigebreite sowie eine pro-Tab-Sitzungs-ID. Der Server fügt das Land (via GeoIP) hinzu und berechnet die Lokalisierungslücke zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und keine Fingerabdrücke erstellt.