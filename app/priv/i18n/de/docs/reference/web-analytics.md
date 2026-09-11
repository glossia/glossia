%{
  title: "Analytik SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpunkt und das Datenschutzmodell hinter der Glossia-Webanalyse.",
  category: "Referenz",
  order: 1
}
---
## Events-Endpoint

`POST /api/analytics/events`

nimmt ein JSON-Event vom `@glossia/web` SDK. Antwortet immer `202 Accepted`, einschließlich unbekannter Domains oder falsch formatierter Payloads, damit der SDK niemals offenlegt, welche Projekte Analytik sammeln.

Das Projekt wird durch die von dem Snippet angegebene Website-Domäne aufgelöst. `d` ist maßgeblich; wenn diese fehlt, greift der Server auf den Host von `u` (die URL der Seite) und dann die Anfrage `Origin`/`Referer`.

### Anfrageinhalt

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domain, die das Projekt identifiziert (z. B. `example.com`). Erforderlich. |
| `n`   | string | Eventname. Standardmäßig `pageview`.                          |
| `u`   | string | Seiten-URL (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Bildschirmbreite in CSS-Pixel.                                  |
| `sid` | string | Sitzungs-ID pro Tab (sessionStorage, gelöscht beim Schließen).       |

CORS ist offen (`Access-Control-Allow-Origin: *`) weil der Endpunkt keine Anmeldedaten akzeptiert.

## Serverseitig abgeleitete Felder

Diese werden beim Import berechnet und serverseitig gespeichert. Die rohen IP-Adressen und User-Agent werden nie gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglicher rotierter Hash von IP + UA + Projekt. Nicht über Tage hinweg verknüpfbar.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2-Code. Leer, wenn GeoIP nicht konfiguriert ist.        |
| `device`          | User-Agent    | `desktop`| `mobile`| `tablet`, `bot`, oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, oder `unknown`.        |
| `hostname`        | Seiten-URL      | host in Kleinbuchstaben.                                                    |
| `pathname`        | Seiten-URL      | Pfadkomponente.                                                     |
| `referrer_source` | Referer      | Referer-Host, führend `www.`/`m.` gestrichen.                        |
| `browser_language`| Sprachen     | Am meisten bevorzugtes normalisiertes Locale (z. B. `pt-BR`).                    |
| `served_locale`   | Berechnet      | Erst unterstütztes Ziel, das einer bevorzugten Sprache entspricht, andernfalls leer.   |
| `has_locale_gap`  | Berechnet      | `1` wenn der Besucher eine Sprache bevorzugt, die das Projekt nicht unterstützt. |

## Datenschutzmodell

- **Keine clientseitige Speicherung.** Das SDK setzt keine Cookies ein und speichert nur eine pro-Tab-Sitzungs-ID in `sessionStorage`, die der Browser beim Schließen löscht.
- **Keine Fingerprinting.** Canvas-, WebGL-, Schriftart- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich rotierende Server-Hash liefert Eindeutigkeit ohne diese.
- **Keine rohen Identifikatoren werden gespeichert.** IP und User-Agent werden einmal abgerufen, mit einem Server-Secret und einem täglichen Salt gehasht und dann verworfen.
- **Projektabgrenzung.** Der gleiche Browser auf zwei Projekten erzeugt unabhängige Besucher-IDs, sodass Besucher nicht zwischen verschiedenen Glossia-Kunden hinweg verfolgt werden können.