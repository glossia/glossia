%{
  title: "Analytics-SDK",
  summary: "Die erfassten Felder, der Ereignis-Endpunkt und das Datenschutzmodell hinter Glossia Web-Analytics.",
  category: "Referenz",
  order: 1
}
---
## Events-Endpunkt

`POST /api/analytics/events`

Akzeptiert ein JSON-Event vom `@glossia/web`-SDK. Antwortet immer mit `202 Accepted`, auch bei unbekannten Domains oder fehlerhaften Payloads, damit das SDK zu keinem Zeitpunkt offenlegt, welche Projekte Analysedaten erfassen.

Das Projekt wird über die vom Snippet deklarierte Website-Domain aufgelöst. `d` ist maßgebend; falls dieser Wert fehlt, greift der Server auf den Host von `u` (die Seiten-URL) und anschließend auf `Origin`/`Referer` zurück.

### Request-Body

| Feld | Typ | Beschreibung |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Website-Domain, die das Projekt identifiziert (z. B. `example.com`). Erforderlich. |
| `n`   | string | Event-Name. Standardwert ist `pageview`.                          |
| `u`   | string | Seiten-URL (`location.href`).                                  |
| `r`   | string | Referrer (`document.referrer`).                              |
| `l`   | string | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Bildschirmbreite in CSS-Pixeln.                                  |
| `sid` | string | Sitzungs-ID pro Tab (sessionStorage, wird beim Schließen gelöscht).       |

CORS ist geöffnet (`Access-Control-Allow-Origin: *`), da der Endpunkt keine Anmeldedaten akzeptiert.

## Vom Server abgeleitete Felder

Diese werden bei der Erfassung berechnet und serverseitig gespeichert. Die rohe IP-Adresse und der User-Agent werden niemals gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotierter Hash von IP + UA + Projekt. Nicht über Tage hinweg verknüpfbar.  |
| `country_code`    | GeoIP         | ISO-3166-1-Alpha-2-Code. Leer, wenn GeoIP nicht konfiguriert ist.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` oder `unknown`.        |
| `hostname`        | Page URL      | Host in Kleinschreibung.                                                    |
| `pathname`        | Page URL      | Pfad-Komponente.                                                     |
| `referrer_source` | Referrer      | Referrer-Host, führende `www.`/`m.` entfernt.                        |
| `browser_language`| Sprachen     | Am meisten bevorzugte, normalisierte Locale (z. B. `pt-BR`).                    |
| `served_locale`   | Berechnet      | Erstes unterstütztes Ziel, das mit einer bevorzugten Sprache übereinstimmt, andernfalls leer.   |
| `has_locale_gap`  | Berechnet      | `1`, wenn der Besucher eine Sprache bevorzugt, die das Projekt nicht anbietet. |

## Datenschutzmodell

- **Keine clientseitige Speicherung.** Das SDK setzt keine Cookies und speichert nur eine sitzungsspezifische ID pro Tab in `sessionStorage`, die der Browser beim Schließen löscht.
- **Kein Fingerprinting.** Canvas-, WebGL-, Schriftart- und Audio-Fingerabdrücke werden nicht erfasst. Der täglich rotierte Server-Hash ermittelt auch ohne diese Merkmale eindeutige Besucher.
- **Keine Speicherung von Rohidentifikatoren.** IP und User-Agent werden einmalig gelesen, mit einem Server-Secret und einem täglichen Salt gehasht und anschließend verworfen.
- **Projektbezogene Abgrenzung.** Derselbe Browser führt bei zwei Projekten zu unabhängigen Besucher-IDs, sodass Besucher nicht über verschiedene Kunden von Glossia hinweg verfolgt werden können.