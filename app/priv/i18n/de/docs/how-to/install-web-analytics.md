%{
  title: "Web-Analytik installieren",
  summary: "Fügen Sie das Glossia Web-SDK mit einer Zeile HTML oder über npm auf Ihrer Website hinzu und sammeln Sie Lokalisierungssignale.",
  category: "how-to",
  order: 1
}
---
Diese Anleitung geht von einem Glossia-Projekt aus, dessen Site-Domain in den Analytics-Einstellungen des Projekts konfiguriert ist. Die Erfassung wird durch diese Domain identifiziert, sodass kein Schlüssel oder Geheimnis kopiert werden muss.

## Option A: script-Tag

Fügen Sie diesen Codeausschnitt jeder Seite hinzu, idealerweise im `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet einen Seitenbesuch beim Laden und protokolliert nachfolgende Seitenbesuche bei der clientseitigen Navigation in Single-Page-Apps. `data-domain` ist standardmäßig auf `window.location.hostname` gesetzt, wenn es weggelassen wird, sodass Sie es auf einer Single-Domain-Website weglassen können. Für einen benutzerdefinierten Collection-Endpunkt können Sie `data-endpoint="https://collect.your-host.com"` hinzufügen.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungseinstiegscode:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Der `domain` wird aus `window.location.hostname` abgeleitet, sodass das SDK gemäß dem für Ihre Seite registrierten Projekt protokolliert. Übergeben Sie `{ domain: "example.com" }`, um dies zu überschreiben, z. B., um Events von einer Staging-Umgebung an dasselbe Projekt wie in der Produktion zu senden.

Um ein benutzerdefiniertes Event aufzuzeichnen, z. B. eine Anmeldung:

```ts
glossia.track("signup");
```

## Überprüfen Sie die Funktionsweise

1. Öffnen Sie Ihre Seite im Browser.
2. Öffnen Sie das Netzwerk-Tab und bestätigen Sie, dass eine `POST`-Anfrage an `/api/analytics/events` mit `202 Accepted` beantwortet wird.
3. Innerhalb einer Minute erscheint der Seitenbesuch im Analytics-Dashboard Ihres Projekts.

## Was gesammelt wird

Der Browser sendet die Seiten-URL, Referrer, `navigator.languages`, Zeitzone und Bildschirmbreite sowie eine pro Tab bestimmte Session-ID. Der Server fügt das Land (aus GeoIP) hinzu und berechnet die Lokalisierungsabstand zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und es wird nicht Fingerprinting durchgeführt.