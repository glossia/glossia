%{
  title: "Analytik-SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpoint und das Datenschutzmodell hinter Glossia Webanalytics.",
  category: "Referenz",
  order: 1
}
---
## Events-Endpunkt

`POST /api/analytics/events`

Akzeptiert ein JSON-Event vom `@glossia/web` SDK. Antwortet immer `202 Accepted`, einschließlich für unbekannte Domains oder fehlerhafte Nutzlasten, so dass das SDK niemals verrät, welche Projekte Analysen sammeln.

Das Projekt wird durch die Site-Domain aufgelöst, die das Snippet angibt. `d` ist autoritativ; wenn sie fehlt, greift der Server auf den Host des `u` (die Seiten-URL) und dann die Anfrage `Origin`/`Referer`.

### Anfrageinhalt

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domain des Standorts, der das Projekt identifiziert (z.B. `example.com`). Erforderlich. |
| `n`   | string | Ereignisname. Standardmäßig `pageview`.                          |
| `u`   | string | URL der Seite (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | Zeichenkette | Browser-Sprachen (`navigator.languages.join(",")`)         |
| `tz`  | string | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | Zahl | Bildschirmbreite in CSS-Pixel. |
| `sid` | string | Sitzungs-ID pro Tab (sessionStorage, beim Schließen gelöscht).       |

CORS ist aktiviert (`Access-Control-Allow-Origin: *`) weil das Endpoint keine Anmeldeinformationen akzeptiert.

## Serverseitige Felder

Diese werden bei der Erfassung berechnet und serverseitig gespeichert. Die rohe IP-Adresse und der User-Agent werden niemals gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotierter Hash von IP + UA + Projekt. Nicht über Tage hinweg verknüpfbar.  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2-Code. Leer, wenn GeoIP nicht konfiguriert ist.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, oder `unknown`.        |
| `hostname`        | Seiten-URL      | kleingeschriebener Host.                                                    |
| `pathname`        | Seiten-URL      | Pfad-Komponente.                                                     |
| `referrer_source` | Referer      | Referer-Host, führend `www.`/`m.` entfernt.                        |
| `browser_language`| Sprachen     | Meist bevorzugte normalisierte Locale (z.B. `pt-BR`).                    |
| `served_locale`   | Berechnet      | Erstes unterstütztes Ziel, das einer bevorzugten Sprache entspricht, sonst leer.   |
| `has_locale_gap`  | Berechnet       | `1` Wenn der Besucher eine Sprache bevorzugt, die das Projekt nicht unterstützt. |

## Datenschutzmodell

- **Keine Speicherung auf der Client-Seite.** Das SDK setzt keine Cookies und speichert nur eine pro-Tab-Sitzungs-ID in `sessionStorage`, die der Browser beim Schließen löscht.
- **Keine Fingerprinting.** Canvas-, WebGL-, Schriftart- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich rotierende Server-Hash liefert eindeutige Kennungen ohne diese.
- **Keine rohen Identifikatoren werden gespeichert.** IP und User-Agent werden einmal abgerufen, mit einem Servergeheimnis und einem täglichen Salt gehasht, dann verworfen.
- **Projektbezogene Abgrenzung.** Der gleiche Browser in zwei Projekten erzeugt nicht verknüpfte Besucher-IDs, sodass Besucher nicht über Glossia-Kunden hinweg nachverfolgt werden können.