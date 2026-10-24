%{
  title: "Analytik-SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpoint und das Datenschutzmodell hinter der Glossia-Web-Analytik.",
  category: "Referenz",
  section: "analytics",
  order: 1
}
---

## Ereignisse-Endpunkt

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` bleibt zur Kompatibilität verfügbar. Das gehostete Skript leitet `/v1/collect` aus seiner eigenen Herkunft ab; Paket-Integrationen sollten `endpoint` explizit festlegen.

Akzeptiert ein JSON-Ereignis vom `@glossia/web` SDK. Reagiert immer mit `202 Accepted`, auch bei unbekannten Domänen oder fehlerhaften Payloads, sodass das SDK niemals enthüllt, welche Projekte Beimessungen sammeln.

Das Projekt wird anhand der Webseite-Domäne gelöst, die das Snippet angibt. `d` ist maßgeblich; wenn es fehlt, fällt der Server auf den Host von `u` (die Seiten-URL) und dann auf die Anfrage `Origin`/`Referer`.

### Anforderungskörper

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Webseite-Domäne, die das Projekt identifiziert (beispielsweise `example.com`). Von der Browser-Bibliothek gesendet; Fallback-Lösung ist oben beschrieben. |
| `n`   | string | Ereignisname. Standardmäßig `pageview`.                          |
| `u`   | string | Seiten-URL (`location.href`).                                  |
| `r`   | string | Verweis (`document.referrer`).                              |
| `l`   | string | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `sl`  | string | Tatsächliche Seitensprache (`document.documentElement.lang`). Leer, wenn nicht erklärt. |
| `al`  | string | Kommasetrennte Übersetzungssprachen aus `link[rel="alternate"][hreflang]`, außer `x-default`. |
| `tz`  | string | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Bildschirmbreite in CSS-Pixeln.                                  |
| `sid` | string | Pro-Tab-Sitzungs-ID (sessionStorage, bei Schließen geleert).       |

CORS ist offen (`Access-Control-Allow-Origin: *`) weil der Endpunkt keine Berechtigungen akzeptiert.

## Server-seitig abgeleitete Felder

Diese werden bei der Erfassung berechnet und serverseitig gespeichert. Der Roh-IP- und User-Agent werden niemals gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotierender Hash von IP + UA + Projekt. Nicht über Tage verlinkbar.  |
| `country_code`    | Cloudflare / GeoIP | ISO 3166-1 alpha-2-Code aus einem vertrauenswürdigen `CF-IPCountry`-Header oder dem konfigurierten IP-Geolokations-Adapter. Leer, wenn keiner ein Land feststellt. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, oder `unknown`.        |
| `hostname`        | Seiten-URL      | kleingeschriebener Host.                                                    |
| `pathname`        | Seiten-URL      | Pfadkomponente.                                                     |
| `referrer_source` | Verweis      | Verweis-Host, führendes `www.`/`m.` gestrichen.                        |
| `browser_language`| Sprachen     | Am besten bevorzugtes normalisiertes Lokal (z.B. `pt-BR`).                    |
| `served_locale`   | Seitensprache | Normalisierte `sl`, oder leer (als Nicht berichtet angezeigt), wenn es nicht gesammelt wurde. |
| `has_locale_gap`  | Berechnet      | `1` wenn keine der bevorzugten Sprachen des Besuchers mit den Projektzielen, den beworbenen Übersetzungen (`al`) oder der Seitensprache (`sl`) übereinstimmen. Fehlende Einstellungen zählen nicht als Lücke. |

### Client-IP-Auflösung

Für Anfragen von einem privaten Ingress-Peer verwendet Glossia den von nginx überschriebenen `X-Real-IP`-Header, nicht den aufrufgesteuerten ersten Eintrag in `X-Forwarded-For`. Direkte öffentliche Verbindungen verwenden die Socket-Adresse. Auf Hetzner müssen sowohl der Load Balancer als auch nginx das PROXY-Protokoll aktivieren, damit nginx die Besucheradresse statt der Load Balancer-Adresse erhält. Andere Reverse-Proxys müssen `X-Real-IP` ebenfalls mit einer authentifizierten Quelle überschreiben, nicht mit einem unbeschränkten einwärtsgerichteten `X-Forwarded-For`-Header. Die allgemeine Richtlinie für fürwortsende-Header allein garantiert dies nicht. Private Peers sind vertrauenswürdige Infrastruktur, daher ist direkter Pod-Zugang zu begrenzen.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` ermöglicht `CF-Connecting-IP` zur Überschreibung der kanonischen Adresse für Anfragen von einem privaten Ingress-Peer. Es ist **standardmäßig deaktiviert**, unabhängig vom Country-Header-Vertrauen. Aktivieren Sie es nur, nachdem die Kante Cloudflare authentifiziert oder gefälschte Header entfernt hat. DNS-only-Deployments sollten es deaktiviert lassen. Diese Adresse steuert auch IP-Rate-Limits und den täglichen Besucher-Hash.

### Country-Auflösung

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` ermöglicht den `CF-IPCountry`-Schnellweg. Es ist **standardmäßig deaktiviert**. Aktivieren Sie es nur, nachdem die Origin Cloudflare authentifiziert hat, Anfragen ablehnt, die Cloudflare umgehen, oder der Ingress nicht vertrauenswürdige Kopien des Headers entfernt. Cloudflares IP-Geolokations-Einstellung muss ebenfalls für die Zone aktiviert sein. `CF-Connecting-IP`, `CF-Ray` und nginx's `use-forwarded-headers` authentifizieren eine Anfrage nicht an sich.

Wenn Header-Vertrauen aktiviert ist, wird ein einzelner gültiger ISO-Landcode sofort verwendet, ohne IP-Abruf oder Cache-Zugriff. Der aktuelle Edge-Wert hat immer Vorrang vor jeder gecachten Abfrage. Fehlende, doppelte, fehlerhafte oder unbekannte Codes, einschließlich von Cloudflares `XX` (unbekannt) und `T1` (Tor)-Werten, wechseln zum konfigurierten Geolokations-Adapter.

Ohne eine konfigurierte MaxMind-Datenbank verwenden Fallback-Abfragen `api.ipapi.is`, dann `api.country.is`, wenn die primäre Anfrage fehlschlägt oder kein erkanntes Land zurückgibt. Jede Anfrage hat eine Verbindungs- und Antwortzeit-Timeout von einer Sekunde mit deaktivierten Rückversuchen. Erfolgreiche Ergebnisse von entwederem Anbieter werden von Cachex für 24 Stunden gecacht, mit einem geplanten Größe-Limit von 100.000 Einträgen und automatischer Expiry-Aufräumung. `Cachex.fetch/3` kollabiert gleichzeitige Fehlschläge für die gleiche IP in einen Resolver. Fehler werden nicht gecacht. Private und reservierte Adressen werden nicht an entwederem Anbieter gesendet.

### Fehlende Seitensprache

Das Dashboard zeigt **Nicht berichtet** an, wenn ein Ereignis keinen `sl` hat. Dies umfasst Ereignisse, die von älteren Tracker-Versionen gesammelt wurden, und Seiten ohne das HTML `lang`-Attribut. Die Seitensprache wird von Browserpräferenzen oder der URL nicht abgeleitet. Historische Ereignisse behalten die zum Zeitpunkt gesammelten Metadaten; neue Tracker-Versionen backfillen sie nicht.

## Privatsphärenmodell

- **Kein dauerhafter Cross-Session-Identifizierer.** Das SDK setzt keine Cookies und speichert nur eine pro-Tab-Sitzungs-ID in `sessionStorage`, die der Browser beim Schließen leert.
- **Kein Fingerprinting.** Canvas-, WebGL-, Font- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich rotierende Server-Hash liefert Uniques ohne diese.
- **Keine rohen Identifizierer gespeichert.** IP und User-Agent werden einmal gelesen, mit einem Server-Schlüssel und einem täglichen Salz gehasht, und dann verworfen.
- **Projektabgrenzung.** Der gleiche Browser auf zwei Projekten liefert unbezogene Besucher-IDs, sodass Besucher nicht über Glossia-Kunden hinweg verfolgt werden können.
