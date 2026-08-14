%{
  title: "Web-Analyse installieren",
  summary: "Fügen Sie das Glossia Web-SDK mit einer einzigen Zeile HTML oder über npm zu Ihrer Website hinzu und beginnen Sie mit der Erfassung von Lokalisierungssignalen.",
  category: "how-to",
  order: 1
}
---
Diese Anleitung setzt voraus, dass Sie ein Glossia-Projekt haben, dessen Website-Domain in den Analytics-Einstellungen des Projekts konfiguriert ist. Die Erfassung wird über diese Domain identifiziert, sodass kein Schlüssel oder Secret kopiert werden muss.

## Option A: script-Tag

Fügen Sie dieses Snippet auf jeder Seite ein, idealerweise im `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet beim Laden einen Seitenaufruf und erfasst nachfolgende Seitenaufrufe bei der clientseitigen Navigation in Single-Page-Anwendungen. `data-domain` wird standardmäßig auf `window.location.hostname` gesetzt, wenn es ausgelassen wird, sodass Sie es auf einer Website mit nur einer Domain weglassen können. Um den Erfassungsendpunkt selbst zu hosten, fügen Sie `data-endpoint="https://collect.your-host.com"` hinzu.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmalig im Einstiegspunkt Ihrer Anwendung:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Der `domain` wird aus `window.location.hostname` abgeleitet, sodass das SDK Daten für das für Ihre Website registrierte Projekt erfasst. Übergeben Sie `{ domain: "example.com" }`, um dies zu überschreiben, beispielsweise um Ereignisse von einem Staging-Origin an dasselbe Projekt wie in der Produktionsumgebung zu senden.

Um ein benutzerdefiniertes Ereignis aufzuzeichnen, beispielsweise eine Registrierung:

```ts
glossia.track("signup");
```

## Funktionsfähigkeit überprüfen

1. Öffnen Sie Ihre Website in einem Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie, dass eine `POST`-Anfrage an `/api/analytics/events` den Status `202 Accepted` zurückgibt.
3. Innerhalb einer Minute erscheint der Seitenaufruf im Analytics-Dashboard Ihres Projekts.

## Was erfasst wird

Der Browser sendet die Seiten-URL, den Referrer, `navigator.languages`, die Zeitzone und die Bildschirmbreite sowie eine Sitzungs-ID pro Tab. Der Server fügt das Land hinzu (aus GeoIP) und berechnet die Lokalisierungslücke im Vergleich zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und es wird kein Fingerprinting durchgeführt.