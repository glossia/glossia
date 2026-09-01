%{
  title: "Analytics SDK",
  summary:
    "Die gesammelten Felder, das Events-Endpoint und das Datenschutzmodell hinter der Glossia-Web-Analytik.",
  category: "Referenz",
  order: 1
}
---
## Events endpunkt

`POST /api/analytics/events`

Akzeptiert ein JSON-Event von der `@glossia/web` SDK. Immer Antwort `202 Accepted`, auch für unbekannte Domänen oder formatting Payloads, sodass das SDK nie geliefert, welche Projekte Analysen sammeln.

Das Projekt wird durch die Website domäne-Snippet erklärt. `d` ist autoritativ; wenn sie fehlt der Server fällt zurück zur `u` (die Seiten-URL) und dann die Anforderung `Origin`/`Referer`.

### Anforderung Körper

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Website domäne das Projekt identifiziert (z. B. `example.com`). Erforderlich. |
| `n`   | string | Ereignisname. Standard `pageview`.                          |
| `u`   | string | Seiten URL (`location.href`).                                  |
| `r`   | string | Herberrer (`document.referrer`).                              |
| `l`   | string | Browser sprachen (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Bildschirmbreite in CSS-Pixeln.                                  |
| `sid` | string | Pro-Sitzung-ID (SessionStorage, geklärt bei schließen).       |

CORS off (`Access-Control-Allow-Origin: *`), da der Endpunkt keine Zugriffsdaten akzeptiert.

## Server-abgeleitete Felder

Diese werden bei der Aufnahme berechnet und serverseitig gespeichert. Der Rohe IP und User-Agent werden nie gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich drehende Hash von IP + UA + Projekt. Nicht verlinkbar über Tage.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 Code. Leer wenn GeoIP nicht konfiguriert.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, oder `unknown`.        |
| `hostname`        | Seiten URL      | Klein geschrieben weiterer.                                                    |
| `pathname`        | Seiten URL      | Pfad-Komponente.                                                     |
| `referrer_source` | Herberrer      | Herberrer-Hersteller, lebende `www.`/`m.` gestreift.                        |
| `browser_language`| Sprachen     | Bevorzugt normalisiert lokal (z. B. `pt-BR`).                    |
| `served_locale`   | Berechnet      | Erste unterstützte Ziel matching bevorzugten Sprache, sonst leer.   |
| `has_locale_gap`  | Berechnet      | `1` wenn Besucher bevorzugte Sprache das Projekt nicht dient. |

## Privatsphären Modell

- **Keine Client-seitige Speicherung.** Der SDK setzt keine Cookies und verwendet nur eine pro-Sitzung ID in `sessionStorage`, welche der Browser bei geschlossen klärt.
- **Keine Fingerabdrücke.** Canvas, WebGL, font, und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich drehende Server-Hash bietet uniques ohne sie.
- **Keine Roh-Identifikatoren gespeichert.** IP und User-Agent werden einmal gelesen, Hash mit einem Serverschlüssel und einem täglichen Salz, dann weggewürfelt.
- **Pro-Projekt-Focus.** Der gleiche Browser auf zwei Projekten liefert unzusammenhängende Besucher-IDs, sodass Besucher nicht über Glossia-Kunden verfolgt werden können.