%{
  title: "Analytics SDK",
  summary:
    "Die gesammelten Felder, das Events-Endpoint und das Datenschutzmodell hinter der Glossia-Webanalyse.",
  category: "Referenz",
  section: "analytics",
  order: 1
}
---
## Events-Endpunkt

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` bleibt aus Kompatibilitätsgründen verfügbar. Das gehostete Skript leitet `/v1/collect` von seiner eigenen Quelle ab; Paket-Integrationen sollten `endpoint` explizit.

Empfängt ein JSON-Event von dem `@glossia/web` SDK. Antwortet immer `202 Accepted`, einschließlich unbekannter Domänen oder fehlerhafter Payloads, sodass das SDK niemals verrät, welche Projekte Analytikdaten erfassen.

Das Projekt wird durch die Website-Domain bestimmt, die das Snippet angibt. `d` ist autoritativ; wenn es fehlt, fällt der Server auf den Host zurück von `u` (die Seiten-URL) und dann die Anfrage `Origin`/`Referer`.

### Anfrageinhalt

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | Zeichenfolge | Domain, die das Projekt identifiziert (z. B. `example.com`). Von der Browserbibliothek gesendet; die Fallback-Lösung ist oben beschrieben. |
| `n`   | string | Ereignisname. Standardwert `pageview`.                          |
| `u`   | string | Seiten-URL (`location.href`)                                  |
| `r`   | Zeichenkette | Referenz (`document.referrer`).                              |
| `l`   | string | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `sl`  | Zeichenkette | Tatsächliche Seitensprache (`document.documentElement.lang`). Leer, wenn nicht deklariert. |
| `al`  | string | Komma-getrennte Übersetzungssprachen von `link[rel="alternate"][hreflang]`, ausgenommen `x-default`. |
| `tz`  | string | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`)
| `sw`  | number | Bildschirmbreite in CSS-Pixel.                                  |
| `sid` | string | Sitzungs-ID pro Tab (sessionStorage, Löschungsstatus beim Schließen).       |

CORS ist offen (`Access-Control-Allow-Origin: *`) weil das Endpoint keine Credentials akzeptiert.

## Server-hergeleitete Felder

Diese werden bei der Ingestion berechnet und serverseitig gespeichert. Die rohen IP-Adresse und User-Agent werden niemals gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglicher rotierter Hash von IP + UA + Projekt. Nicht über Tage verknüpfbar. |
| `country_code`    | Cloudflare / GeoIP | ISO 3166-1 alpha-2-Code von einem vertrauenswürdig `CF-IPCountry` Header, oder der konfigurierten IP-Geolokalisierungs-Adapter. Leer, wenn keines ein Land auflöst. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`Das neu zusammengeführte Dokument hatte zuvor die Validierung nicht bestanden: Die Wiederherstellung eines Markdown-Textknotens ergab eine leere Übersetzung. `safari`Das neu zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textknoten ergab eine leere Übersetzung. `firefox`Das neu zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textknoten erzeugte eine leere Übersetzung. `edge`Das neu zusammengeführte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textknoten ergab eine leere Übersetzung `opera`, oder `unknown`.       |
| `os`              | User-Agent    | `windows`Das neu zusammengesetzte Dokument hat die Validierung zuvor nicht bestanden: Die Wiederherstellung von Markdown-Text-Literalen gab ungültiges JSON zurück. `macos`Das neu zusammengeführte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Textliterals hat ungültiges JSON zurückgegeben. `ios`, `android`, `linux`, oder `unknown`.        |
| `hostname`        | URL der Seite      | Host in Kleinbuchstaben.                                                    |
| `pathname`        | URL der Seite       | Pfadkomponente.                                                     |
| `referrer_source` | Referer      | Referer-Host, führend `www.`/`m.` gekürzt.                        |
| `browser_language`| Sprachen     | Bevorzugte normalisierte Lokaleinstellung (z.B. `pt-BR`).                    |
| `served_locale`   | Seitensprache | Normalisiert `sl`oder leer (als „Nicht gemeldet“ angezeigt), wenn es nicht gesammelt wurde. |
| `has_locale_gap`  | Berechnet      | `1` wenn keine der bevorzugten Sprachen des Besuchers mit den Projektzielen, den angekündigten Übersetzungen (`al`), oder der Seitensprache übereinstimmen (`sl`). Fehlende Einstellungen zählen nicht als Lücke. |

### Länderauflösung

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` ermöglicht den `CF-IPCountry` Schnellpfad. Es ist **standardmäßig deaktiviert**. Aktivieren Sie es nur, wenn der Ursprung Cloudflare authentifiziert hat, Anfragen ablehnt, die Cloudflare umgehen, oder der Ingress nicht vertrauenswürdige Kopien des-Headers entfernt. Die Cloudflare IP-Geolokalisierungseinstellung muss zudem für die Zone aktiviert sein. `CF-Connecting-IP`, `CF-Ray`, und nginx `use-forwarded-headers` authentifizieren keine Anfrage eigenständig.

Wenn das Header-Vertrauen aktiviert ist, wird sofort ein einziger gültiger ISO-Ländercode verwendet, ohne IP-Abfrage oder Cache-Zugriff. Der aktuelle Edge-Wert hat stets Vorrang vor jeder zwischengespeicherten Suche. Fehlende, doppelte, fehlerhafte oder unbekannte Codes, einschließlich Cloudflare. `XX` (unbekannt) und `T1` (Tor)-Werte; auf den konfigurierten Geolokations-Adapter zurückfallen.

Ohne eine konfigurierte MaxMind-Datenbank nutzen Fallback-Abfragen `api.ipapi.is`, dann `api.country.is` wenn die primäre Anfrage fehlschlägt oder kein erkanntes Land zurückgibt. Jede Anfrage verfügt über einen Verbindungs- und Antwort-Timeout von einer Sekunde mit deaktivierten Wiederholungsversuchen. Erfolgreiche Ergebnisse von beiden Anbietern werden von Cachex für 24 Stunden zwischengespeichert, mit einem geplanten Größenlimit von 100.000-Einträgen und automatischer Bereinigung bei Ablauf. `Cachex.fetch/3` kombiniert parallele Fehlversuche für dieselbe IP in einem Resolver. Fehler werden nicht zwischengespeichert. Private und reservierte Adressen werden an keinen der Anbieter gesendet.

### Fehlende Seiten-Sprache

Das Dashboard zeigt **Nicht berichtet** wenn ein Event kein `sl`. Dies umfasst Ereignisse, die von älteren Tracker-Versionen gesammelt wurden und Seiten ohne ein HTML `lang` Attribut. Die Pagensprache wird nicht aus Browserpräferenzen oder der URL abgeleitet. Historische Ereignisse behalten die zum Zeitpunkt gesammelten Metadaten; neue Tracker-Versionen ergänzen sie nicht.

## Datenschutzmodell

- **Kein dauerhafter Cross-Session-Identifikator.** Das SDK setzt keine Cookies und speichert nur eine pro-Tab-Sitzungs-ID in `sessionStorage`, die der Browser beim Schließen löscht.
- **Kein Fingerprinting.** Canvas, WebGL, Schriftart- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich rotierende Server-Hash liefert eindeutige Werte, ohne sie.
- **Keine rohen Identifikatoren werden persistiert.** IP und User-Agent werden einmal ausgelesen, mit einem Server-Secret und einem täglichen Salz gehasht und danach verworfen.
- **Projektabgrenzung.** Der gleiche Browser auf zwei Projekten liefert unabhängige Besucher-IDs, sodass Besucher nicht über Glossia-Kunden hinweg verfolgt werden können.