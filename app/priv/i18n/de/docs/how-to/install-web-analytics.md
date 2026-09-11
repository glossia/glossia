%{
  title: "Webanalyse installieren",
  summary:
    "Fügen Sie das Glossia Web SDK Ihrer Website mit einer Zeile HTML oder über npm hinzu und sammeln Sie Lokalisierungssignale.",
  category: "Anleitung",
  order: 1
}
---
Diese Anleitung geht davon aus, dass Sie ein Glossia-Projekt besitzen, dessen Site-Domain in den Analytics-Einstellungen des Projekts konfiguriert ist. Die Kollektion wird durch diese Domain identifiziert, sodass kein Schlüssel oder Geheimwert kopiert werden muss.

## Option A: Script-Tag

Fügen Sie diesen Codeausschnitt idealerweise auf jeder Seite in die `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, meldet beim Laden einen Seitenbesuch und protokolliert nachfolgende Seitenbesuche bei der clientseitigen Navigation in Single-Page-Anwendungen. `data-domain` wird standardmäßig verwendet `window.location.hostname` wird beim Weglassen verwendet, sodass Sie es auf einer Single-Domain-Seite einfügen können. Um einen benutzerdefinierten Kollektions-Endpunkt zu nutzen, fügen Sie hinzu `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Installieren Sie das Paket:

```bash
npm install @glossia/web
```

Initialisieren Sie es einmal in Ihrem Anwendungseinstiegspunkt:

```ts
import glossia from "@glossia/web";

glossia.init();
```

Das `domain` wird daraus abgeleitet `window.location.hostname` registriert das SDK für das für Ihre Site registrierte Projekt. Geben Sie `{ domain: "example.com" }` um zu überschreiben, beispielsweise Ereignisse von einem Staging-Origine an das gleiche Projekt wie in der Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu protokollieren, beispielsweise eine Anmeldung:

```ts
glossia.track("signup");
```

## Überprüfe, ob es funktioniert

1. Öffne deine Website in einem Browser.
2. Öffne den Netzwerk-Tab und bestätige eine `POST` Anfrage an `/api/analytics/events` zurückgibt `202 Accepted`.
3. Innerhalb einer Minute erscheint der Seitenaufruf im Analytik-Dashboard deines Projekts.

## Was wird gesammelt

Der Browser sendet die Page-URL, den Referrer, `navigator.languages`, Zeitzonen und Bildschirmbreite, sowie eine pro-Tab-Sitzungs-ID. Der Server fügt das Land hinzu (aus GeoIP) und berechnet den Lokalisierungsabstand zu den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und nichts wird ausgefingert.