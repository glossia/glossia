%{
  title: "Analytics SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpoint und das Datenschutzmodell hinter Glossia Web-Analytics.",
  category: "Referenz",
  section: "analytics",
  order: 1
}
---

## Event-Endpoint

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` bleibt zur Kompatibilität erhalten. Das gehostete Skript leitet `/v1/collect` aus seiner eigenen Ursprung ab; Paketintegrationen sollten `endpoint` explizit setzen.

Akzeptiert ein JSON-Event vom `@glossia/web` SDK. Antwortet immer `202 Accepted`, auch für unbekannte Domains oder fehlerhafte Payloads, sodass das SDK niemals verrät, welche Projekte Analysen sammeln.

Das Projekt wird über die Site-Domain gelöst, die das Snippet angibt. `d` ist maßgeblich; liegt es nicht vor, fällt der Server auf den Host von `u` (die Seiten-URL) und dann auf die Anfrage-Header `Origin`/`Referer` zurück.

### Anfragekörper

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | Zeichenkette | Site-Domain, die das Projekt identifiziert (z. B. `example.com`). Von der Browser-Bibliothek gesendet; die Fallback-Auflösung ist oben beschrieben. |
| `n`   | Zeichenkette | Ereignisname. Standards `pageview`.                          |
| `u`   | Zeichenkette | Seiten-URL (`location.href`).                                  |
| `r`   | Zeichenkette | Referrer (`document.referrer`).                              |
| `l`   | Zeichenkette | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `sl`  | Zeichenkette | Tatsächliche Seitensprache (`document.documentElement.lang`). Leer, wenn nicht deklariert. |
| `al`  | Zeichenkette | Kommagetrennte Übersetzungssprachen aus `link[rel="alternate"][hreflang]`, ausgenommen `x-default`. |
| `tz`  | Zeichenkette | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | Zahl | Bildschirmbreite in CSS-Pixeln.                                  |
| `sid` | Zeichenkette | Pro-Tab-Sitzungs-ID (sessionStorage, bei Schließen geleert).       |

CORS ist offen (`Access-Control-Allow-Origin: *`) da das Endpunkt keine Credentials akzeptiert.

## Server-abgeleitete Felder

Diese werden bei der Ingestion berechnet und serverseitig gespeichert. Die Roh-IP und User-Agent werden nie gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotierender Hash von IP + UA + Projekt. Über Tage nicht verlinkbar.  |
| `country_code`    | Cloudflare / GeoIP | ISO-3166-1 alpha-2-Code aus einem vertrauenswürdigen `CF-IPCountry`-Header oder dem konfigurierten IP-Geolokationsadapter. Leer, wenn keines ein Land ermittelt. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` oder `unknown`.        |
| `hostname`        | Seiten-URL      | Kleingeschriebener Host.                                                    |
| `pathname`        | Seiten-URL      | Verzeichnis-Komponente.                                                     |
| `referrer_source` | Referrer      | Referrer-Host, führende `www.`/`m.` gestrichenen.                        |
| `browser_language`| Sprachen     | Meist bevorzugte normalisierte Locale (z. B. `pt-BR`).                    |
| `served_locale`   | Seitensprache | Normalisiertes `sl`, oder leer (als Nicht berichtet angezeigt), wenn es nicht gesammelt wurde. |
| `has_locale_gap`  | Berechnet      | `1` wenn eines der bevorzugten Sprachen des Visitors mit den Projektzielen, den angebotenen Übersetzungen (`al`) oder der Seitensprache (`sl`) übereinstimmt. Fehlende Präferenzen gelten nicht als Gap. |

### Landserfassung

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` aktiviert den `CF-IPCountry` Startpfad. Er ist **standardmäßig deaktiviert**. Aktivieren Sie ihn nur, nachdem der Ursprung Cloudflare authentifiziert, Anfragen ablehnt, die Cloudflare umgehen, oder der Ingress nicht vertrauenswürdige Kopien des Headers gestrichen hat. Die Cloudflare IP Geolocation-Einstellung muss auch für die Zone aktiviert sein. `CF-Connecting-IP`, `CF-Ray` und nginx's `use-forwarded-headers` authentifizieren eine Anfrage eigenständig nicht.

Wenn Header-Vertrauen aktiviert ist, wird ein einzelner gültiger ISO-Ländrcode sofort verwendet, ohne IP-Suche oder Caches-Zugriff. Der aktuelle Randwert hat immer Vorrang gegenüber jedem gecachten Lookup. Fehlende, doppelte, falschformatierte oder unbekannte Codes, einschließlich Cloudflares `XX` (unbekannt) und `T1` (Tor)-Werte, fallen zurück auf den konfigurierten Geolokationsadapter.

Ohne eine konfigurierte MaxMind-Datenbank nutzen Fallback-Lookups `api.ipapi.is`, dann `api.country.is` wenn die primäre Anfrage fehlschlägt oder kein erkanntes Land zurückgibt. Jede Anfrage hat eine Verbindung- und Antwortzeit von einer Sekunde mit zurückgestellten Versuchen deaktiviert. Erfolgreiche Ergebnisse von jedem Anbieter werden von Cachex für 24 Stunden gecacht, mit einem 100.000-Einträge geplanten Größenlimit und automatischer Ablauf-Rückgewinnung. `Cachex.fetch/3` klappt gleiche IP zusammen bei gleichen fehlgeschlagenen Resolver in einen Resolver. Fehler werden nicht gecacht. Private und reservierte Adressen werden an keinen Anbieter gesendet.

### Fehlende Seitensprache

Das Dashboard zeigt **Nicht berichtet** an, wenn ein Event kein `sl` hat. Dies schließt Events ein, die von älteren Tracker-Versionen gesammelt wurden und Seiten ohne einen HTML `lang`-Attribut. Die Seitensprache wird nicht aus Browserpräferenzen oder der URL abgeleitet. Historische Events behalten die zum Zeitpunkt gesammelten Metadaten; neue Tracker-Versionen füllt sie nicht nach.

## Datenschutzmodell

- **Kein permanentes über Sessions hinweg Identifikator.** Das SDK setzt keine Cookies und speichert nur eine pro-Tab Sitzungs-ID in `sessionStorage`, die der Browser bei Schließen löscht.
- **Kein Fingerabdrücken.** Canvas, WebGL, Schriftart- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich rotierte Server-Hash bietet Uniques ohne sie.
- **Keine Roh-Identifikatoren gespeichert.** IP und User-Agent werden einmal ausgelesen, mit einem Server-Secret und einem täglichen Salz gehasht, dann verworfen.
- **Pro-Projekt Scope.** Der gleiche Browser an zwei Projekten ergibt unverbundene Visitor-IDs, sodass Besucher nicht über Glossia-Kunden hinweg verfolgt werden können.
