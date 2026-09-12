%{
  title: "Analytik SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpunkt und das Datenschutzmodell hinter der Glossia-Webanalyse.",
  category: "Referenz",
  order: 1
}
---
## Events-Endpunkt

`POST /api/analytics/events`

Akzeptiert ein JSON-Ereignis vom `@glossia/web` SDK. Antwortet immer `202 Accepted`, auch für unbekannte Domains oder fehlerhafte Payloads, damit das SDK nie verrät, welche Projekte Analysendaten erfassen.

Das Projekt wird durch die Site-Domain bestimmt, die das Snippet angibt. `d` ist verbindlich; wenn sie fehlt, greift der Server auf den Host von `u` (die Seiten-URL) und danach die Anfrage `Origin`/`Referer`.

### Anfrageinhalt

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domain, die das Projekt identifiziert (z. B.) `example.com`Erforderlich. |
| `n`   | string | Ereignisname. Standardwert `pageview`.                          |
| `u`   | string | Seiten-URL (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | String | Browser-Sprachen (`navigator.languages.join(",")`)         |
| `tz`  | String | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Bildschirmbreite in CSS-Pixeln.                                  |
| `sid` | string | Sitzungs-ID pro Reiter (sessionStorage, bei Schließen geleert).       |

CORS ist offen (`Access-Control-Allow-Origin: *`) da der Endpunkt keine Credentials akzeptiert.

## Server-abgeleitete Felder

Diese werden bei der Datenaufnahme berechnet und serverseitig gespeichert. Die rohe IP-Adresse und der User-Agent werden niemals gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglicher rotierter Hash von IP + UA + Projekt. Nicht tagesübergreifend verknüpfbar.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2-Code. Leer, wenn GeoIP nicht konfiguriert ist.        |
| `device`          | User-Agent    | `desktop`| `mobile`| `tablet`, `bot`, oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, or `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`Das zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textliterals ergab ungültiges JSON. `linux`..., oder `unknown`.        |
| `hostname`        | URL der Seite      | Host in Kleinbuchstaben.                                                    |
| `pathname`        | URL der Seite      | Pfadkomponente.                                                     |
| `referrer_source` | Referer      | Referer-Host, führend `www.`/`m.` gestrichen.                        |
| `browser_language`| Sprachen     | Das am besten bevorzugte, normalisierte Lokale (z.B. `pt-BR`).                    |
| `served_locale`   | Berechnet      | Erstes unterstütztes Ziel, das einer bevorzugten Sprache entspricht, sonst leer.   |
| `has_locale_gap`  | Berechnet      | `1` wenn der Besucher eine Sprache bevorzugt, die das Projekt nicht unterstützt. |

## Datenschutzmodell

- **Keine clientseitige Speicherung.** Das SDK setzt keine Cookies an und speichert nur eine pro-Tab-Sitzungs-ID in `sessionStorage`, "die der Browser beim Schließen löscht.
- **Keine Fingerprinting.** Canvas-, WebGL-, Schriftart- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich neu generierte Server-Hash liefert eindeutige Identifikatoren ohne diese.
- **Keine rohen Identifikatoren werden gespeichert.** IP und User-Agent werden einmal gelesen, mit einem Server-Geheimnis und einem täglichen Salz gehasht und dann verworfen.
- **Projektabgrenzung.** Der gleiche Browser auf zwei Projekten liefert unterschiedliche Besucher-IDs, sodass Besucher nicht über Glossia-Kunden hinweg verfolgt werden können.