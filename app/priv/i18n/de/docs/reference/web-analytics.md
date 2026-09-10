%{
  title: "Analytik-SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpunkt und das Datenschutzmodell hinter der Glossia-Webanalyse.",
  category: "Referenz",
  order: 1
}
---
## Events-Endpoint

`POST /api/analytics/events`

nimmt ein JSON-Ereignis vom `@glossia/web` SDK. Antwortet immer `202 Accepted`, einschließlich für unbekannte Domains oder falsch formatierte Payloads, so dass das SDK niemals verrät, welche Projekte Analysen sammeln.

Das Projekt wird durch die vom Snippet angegebene Site-Domain gelöst. `d` ist autoritativ; wenn es fehlt, fällt der Server auf den Host des `u` (die URL der Seite) und dann die Anfrage `Origin`/`Referer`.

### Anfrage-Body

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domäne, die das Projekt identifiziert (z.B. `example.com`). Erforderlich. |
| `n`   | string | Ereignisname. Standard `pageview`.                          |
| `u`   | string | Seiten-URL (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Browser-Sprachen (`navigator.languages.join(",")`).     |
| `tz`  | string | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Bildschirmbreite in CSS-Pixel.                                  |
| `sid` | string | Sitzungs-ID pro Tab (sessionStorage, beim Schließen gelöscht).       |

CORS ist offen (`Access-Control-Allow-Origin: *`) weil der Endpunkt keine Credentials akzeptiert.

## Server-ableitete Felder

Diese werden bei der Ingestion berechnet und serverseitig gespeichert. Die rohen IP-Adressen und User-Agent werden nie gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotierender Hash von IP + UA + Projekt. Nicht über Tage hinweg verknüpfbar.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 Code. Leer, wenn GeoIP nicht konfiguriert ist.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`- oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`Das zuvor neu zusammengesetzte Dokument hat die Validierung nicht bestanden: die übersetzte Ausgabe war leer bei nicht-leeren Quellinhalt `opera`oder `unknown`.       |
| `os`              | Benutzer-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, oder `unknown`.        |
| `hostname`        | Seiten-URL      | Host in Kleinbuchstaben.                                                    |
| `pathname`        | Seiten-URL      | Pfadkomponente.                                                     |
| `referrer_source` | Referrer      | Referrer host, führend `www.`/`m.` entfernt.                        |
| `browser_language`| Sprachen     | Bevorzugte normalisierte Sprache (beispielsweise `pt-BR`).                    |
| `served_locale`   | Berechnet      | Erstes unterstütztes Ziel, das einer bevorzugten Sprache entspricht, sonst leer.   |
| `has_locale_gap`  | Berechnet      | `1` wenn der Besucher eine Sprache bevorzugt, die das Projekt nicht unterstützt. |

## Datenschutzmodell

- **Keine clientseitige Speicherung.** Das SDK setzt keine Cookies und speichert nur eine pro-Tab-Sitzungs-ID in `sessionStorage`, die der Browser beim Schließen löscht.
- **Kein Fingerprinting.** Canvas-, WebGL-, Font- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich rotierende Server-Hash liefert eindeutige Identifikatoren ohne diese.
- **Keine Roh-Identifikatoren werden gespeichert.** IP und User-Agent werden einmal gelesen, mit einem Server-Geheimnis und einem täglichen Salt gehasht und anschließend verworfen.
- **Projektabgrenzung.** Der gleiche Browser auf zwei Projekten generiert nicht verwandte Besucher-IDs, sodass Besucher über Glossia-Kunden hinweg nicht verfolgt werden können.