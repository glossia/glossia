%{
  title: "Web-Analytics installieren",
  summary:
    "Integrieren Sie das Glossia Web SDK auf Ihrer Seite mit nur einer Zeile HTML oder über npm und beginnen Sie, Lokalisierungssignale zu sammeln.",
  category: "Anleitung",
  order: 1
}
---
Diese Anleitung setzt voraus, dass Sie ein Glossia-Projekt besitzen, dessen Domain der Seite in den Analyseeinstellungen des Projekts konfiguriert ist. Die Datensammlung wird durch diese Domain identifiziert, sodass kein Schlüssel oder Geheimnis zum Kopieren erforderlich ist.

## Option A: Skript-Tag

Fügen Sie diesen Ausschnitt in jede Seite ein, idealerweise im `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Das SDK initialisiert sich automatisch, sendet eine Seitenansicht beim Laden und protokolliert nachfolgende Seitenansichten bei der clientseitigen Navigation in Single-Page-Apps. `data-domain` defaultiert auf `window.location.hostname`, wenn es weggelassen wird, sodass Sie es auf einer Single-Domain-Seite weglassen können. Um einen benutzerdefinierten Datensammlungs-Endpunkt zu verwenden, fügen Sie `data-endpoint="https://collect.your-host.com"` hinzu.

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

Die `domain` wird aus `window.location.hostname` abgeleitet, sodass das SDK beim für Ihre Site registrierten Projekt verzeichnet. Geben Sie `{ domain: "example.com" }` an, um dies zu überschreiben, zum Beispiel, um Events von einem Staging-Origin an dasselbe Projekt wie für die Produktion zu senden.

Um ein benutzerdefiniertes Ereignis zu protokollieren, zum Beispiel eine Anmeldung:

```ts
glossia.track("signup");
```

## Überprüfung der Funktionsweise

1. Öffnen Sie Ihre Seite im Browser.
2. Öffnen Sie den Netzwerk-Tab und bestätigen Sie, dass eine `POST`-Anfrage an `/api/analytics/events` den Wert `202 Accepted` zurückgibt.
3. Innerhalb einer Minute erscheint die Seitenansicht im Analyse-Dashboard Ihres Projekts.

## Was wird gesammelt

Der Browser sendet die URL der Seite, den Referrer, `navigator.languages`, die Zeitzone und die Bildschirmbreite sowie eine pro-Tab-Sitzungs-ID. Der Server fügt das Land hinzu (von GeoIP) und berechnet die Lokalisierungslücke gegenüber den Zielsprachen Ihres Projekts. Es werden keine Cookies gesetzt und kein Fingerprinting durchgeführt.