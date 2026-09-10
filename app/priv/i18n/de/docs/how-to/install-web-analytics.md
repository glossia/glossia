%{
  title: "Web-Analytik installieren",
  summary:
    "Fügen Sie das Glossia Web-SDK Ihrer Website mit einer Zeile HTML oder über npm hinzu und beginnen Sie, Lokalisierungssignale zu erfassen.",
  category: "Anleitung",
  order: 1
}
---
Dieser Guide geht davon aus, dass Sie ein Glossia-Projekt haben, bei dem die Site-Domain in den AnalysEinstellungen des Projekts konfiguriert ist. Collection wird über diese Domain identifiziert, so dass kein Schlüssel oder Geheimnis kopiert werden muss.

## Option A: Script-Tag

Fügen Sie diesen Snippet auf jede Seite ein, idealerweise im `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Die SDK initialisiert sich automatisch, sendet eine Pageview beim Laden und zeichnet nachfolgende Pageviews bei Client-seitiger Navigation in Single-Page-Apps auf. `data-domain` standardmäßig `window.location.hostname` wenn sie weggelassen wird können Sie sie auf einer Single-Domain-Site verwenden. Um ein benutzerdefiniertes Collection-Endpoint zu verwenden, fügen Sie hinzu `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungs-Eingriffspunkt:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Das `domain` wird abgeleitet aus `window.location.hostname` so dass das SDK an das für Ihre Website registrierte Projekt gebunden wird. Geben Sie `{ domain: "example.com" }` um das zu überschreiben, z. B. um Ereignisse von einem staging-Origin an das gleiche Projekt wie die Produktion zu senden.

Um ein benutzerdefiniertes Ereignis aufzuzeichnen, z. B. eine Anmeldung:

```ts
glossia.track("signup");
```

## Überprüfen Sie, ob es funktioniert.

1. Öffnen Sie Ihre Website in einem Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie eine `POST` Anfrage an `/api/analytics/events` zurückgibt `202 Accepted`.
3. Innerhalb einer Minute erscheint die Seitenansicht im Analytik-Dashboard Ihres Projekts.

## Was wird gesammelt

Der Browser sendet die Page-URL, den Referer, `navigator.languages`, Zeitzone sowie Bildschirmbreite plus eine pro-Tab-Sitzungs-ID. Der Server ermittelt das Land (via GeoIP) und berechnet die Lokalisierungslücke zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und kein Fingerprinting betrieben.