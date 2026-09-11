%{
  title: "Webanalytik installieren",
  summary:
    "Fügen Sie das Glossia Web-SDK auf Ihrer Website mit einer Zeile HTML oder über npm hinzu und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  order: 1
}
---
Dieser Leitfaden setzt voraus, dass Sie ein Glossia-Projekt besitzen, dessen Domain in den Analyse-Einstellungen des Projekts konfiguriert ist. Die Datenerfassung wird durch diese Domain identifiziert, sodass kein Schlüssel oder Secret kopiert werden muss.

## Option A: Script-Tag

Fügen Sie diesen Code-Ausschnitt auf jede Seite hinzu, idealerweise in der `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet eine Pageview beim Laden und erfasst nachfolgende Pageviews bei Clientseitiger Navigation in Single-Page-Anwendungen. `data-domain` wird standardmäßig auf `window.location.hostname` wenn es weggelassen wird, können Sie es daher auf einer Single-Domain-Site verwenden. Um einen benutzerdefinierten Datenerfassungs-Endpunkt zu verwenden, fügen Sie hinzu `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungseintrittspunkt:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Das `domain` wird abgeleitet aus `window.location.hostname` so wird das SDK dem für Ihre Website registrierten Projekt zugeordnet. Geben Sie `{ domain: "example.com" }` um dies zu überschreiben, z. B. um Ereignisse von einem Staging-Ursprung an dasselbe Projekt wie in der Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu erfassen, z. B. einer Registrierung:

```ts
glossia.track("signup");
```

## Überprüfen Sie, ob es funktioniert

1. Öffnen Sie Ihre Website im Browser.
2. Öffnen Sie den Netzwerkreiter und bestätigen Sie eine `POST` Anfrage an `/api/analytics/events` antwortet `202 Accepted`.
3. Innerhalb einer Minute erscheint die Seitenansicht im Analyse-Dashboard Ihres Projekts.

## Was gesammelt wird

Der Browser sendet die Seiten-URL, Referrer, `navigator.languages`Zeitzone, Bildschirmbreite, plus eine pro-Tab Session-ID. Der Server fügt das Land (via GeoIP) hinzu und berechnet den Lokalisierungs-Abstand zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und nichts wird als Fingerabdruck erfasst.