%{
  title: "Analytik SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpunkt und das Datenschutzmodell hinter Glossia Web-Analytik.",
  category: "Referenz",
  section: "analytics",
  order: 1
}
---

## Events-Endpunkt

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` bleibt aus Kompatibilitätsgründen weiterhin verfügbar. Das gehostete Skript leitet `/v1/collect` aus seinem eigenen Ursprung ab; Paketintegrationen sollten `endpoint` explizit setzen.

Nimmt ein JSON-Event vom `@glossia/web`-SDK entgegen. Antwortet stets `202 Accepted`, einschließlich unbekannter Domains oder falsch geformter Payloads, so dass das SDK nie verrät, welche Projekte Analysen sammeln.

Das Projekt wird über die Site-Domain ermittelt, die das Snippet deklariert. `d` ist maßgeblich; wenn es fehlt, fällt der Server auf den Host von `u` (die Seiten-URL) und dann auf die Anfrage `Origin`/`Referer` zurück.

### Anfrageinhalt

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | Zeichenkette | Seitendomäne, die das Projekt identifiziert (z. B. `example.com`). Vom Browser-Bibliothek gesendet; die Fallback-Auflösung wird oben beschrieben. |
| `n`   | Zeichenkette | Ereignisname. Standardmäßig `pageview`.                          |
| `u`   | Zeichenkette | Seiten-URL (`location.href`).                                  |
| `r`   | Zeichenkette | Referer (`document.referrer`).                              |
| `l`   | Zeichenkette | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `sl`  | Zeichenkette | Tatsächliche Seiten-Sprache (`document.documentElement.lang`). Leer, wenn nicht angegeben. |
| `al`  | Zeichenkette | Kommagetrennte Übersetzungssprachen aus `link[rel="alternate"][hreflang]`, ausgeschlossen `x-default`. |
| `tz`  | Zeichenkette | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | Numerisch | Bildschirmbreite in CSS-Pixeln.                                  |
| `sid` | Zeichenkette | Sitzungs-ID pro Tab (sessionStorage, beim Schließen geleert).       |

CORS ist offen (`Access-Control-Allow-Origin: *`) weil der Endpunkt keine Anmeldeinformationen akzeptiert.

## Serverseitig abgeleitete Felder

Diese werden bei der Aufnehmens berechnet und serverseitig gespeichert. Die Roh-IP und User-Agent werden niemals gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotierender Hash von IP + UA + Projekt. Keine Verknüpfung über verschiedene Tage hinweg möglich.  |
| `country_code`    | Cloudflare / GeoIP | ISO-3166-1-Alpha-2-Code aus einem vertrauenswürdigen `CF-IPCountry`-Header oder dem konfigurierten IP-Geolokations-Adapter. Leer, wenn keines der beiden ein Land ermittelt. |
| `device`          | Benutzeragent    | `desktop`, `mobile`, `tablet`, `bot` oder `unknown`.                 |
| `browser`         | Benutzeragent    | `chrome`, `safari`, `firefox`, `edge`, `opera` oder `unknown`.       |
| `os`              | Benutzeragent    | `windows`, `macos`, `ios`, `android`, `linux` oder `unknown`.        |
| `hostname`        | Seiten-URL      | Host in Kleinschreibung.                                                    |
| `pathname`        | Seiten-URL      | Pfadkomponente.                                                     |
| `referrer_source` | Referer      | Referer-Host, führende `www.`/`m.` gestrichen.                        |
| `browser_language`| Sprachen     | Am häufigsten bevorzugtes normiertes Locale (z. B. `pt-BR`).                    |
| `served_locale`   | Seiten-Sprache | Normalisiert `sl`, oder leer (als Nicht gemeldet angezeigt), wenn es nicht gesammelt wurde. |
| `has_locale_gap`  | Berechnet      | `1` wenn keine der bevorzugten Sprachen des Besuchers mit den Projektzielen, beworbenen Übersetzungen (`al`) oder Seiten-Sprache (`sl`) übereinstimmen. Fehlende Präferenzen gelten nicht als Lücke. |

### Auflösung der Client-IP

Für Anfragen von einem privaten Ingress-Peer verwendet Glossia nginx's überschriebenen `X-Real-IP`-Header anstelle des vom Caller gesteuerten ersten Eintrags in `X-Forwarded-For`. Direkte öffentliche Verbindungen nutzen die Socket-Adresse. Auf Hetzner müssen sowohl Load Balancer als auch nginx PROXY-Protokoll aktivieren, damit nginx die Besucheradresse statt der Load Balancer-Adresse erhält. Andere Reverse Proxies müssen `X-Real-IP` ebenfalls mit einer authentisierten Quelle überschreiben, nicht mit einem unbeschränkten eingehenden `X-Forwarded-For`-Header. Die generischen Charts' forward-header-Policy allein garantiert dies nicht. Private Peers sind vertrauenswürdige Infrastruktur, daher eingeschränkten direkten Pod-Zugriff.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` ermöglicht `CF-Connecting-IP` die Überschreibung der kanonischen Adresse für Anfragen von einem privaten Ingress-Peer. Es ist **standardmäßig deaktiviert**, unabhängig vom Land-Header-Vertrauen. Aktivieren Sie es nur nach dem Authentifizieren von Cloudflare durch die Kante oder dem Abschneiden gefälschter Header bei Anforderungen, die Cloudflare umgehen. NFS-only-Deploymenten sollten es deaktiviert lassen. Diese Adresse schließt auch IP-Rate-Limits und den täglichen Besucher-Hash ein.

### Land-Auflösung

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` aktiviert den `CF-IPCountry`-Schnellweg. Es ist **standardmäßig deaktiviert**. Aktivieren Sie es nur nach dem Authentifizieren von Cloudflare durch den Ursprung, dem Ablehnen von Anforderungen, die Cloudflare umgehen, oder dem Abschneiden unzuverlässiger Kopien des Headers. Cloudflare's IP-Geolokationseinstellung muss auch für die Zone aktiviert sein. `CF-Connecting-IP`, `CF-Ray` und nginx `use-forwarded-headers` authentifizieren eine Anfrage nicht allein.

Wenn Header-Vertrauen aktiviert ist, wird ein einzelner gültiger ISO-Land-Code sofort verwendet, ohne eine IP-Nachschlage oder Cache-Zugriff. Der aktuelle Rand-Wert hat immer Vorrang vor einem gecachten Nachschlage. Fehlende, doppelte, falsch geformte oder unbekannte Codes, einschließlich Cloudflare's `XX` (unbekannt) und `T1` (Tor) Werte, greifen zurück auf den konfigurierten Geolokations-Adapter.

Ohne eine konfigurierte MaxMind-Datenbank verwenden Fallback-Aufrufungen `api.ipapi.is`, dann `api.country.is` wenn die primäre Anfrage fehlschlägt oder kein erkennbares Land zurückgibt. Jede Anfrage hat eine Verbindung- und Antwortzeitlimit von einer Sekunde ohne Wiederversuche. Erfolgreiche Ergebnisse von jedem Anbieter werden von Cachex für 24 Stunden zwischengespeichert, mit einem 100.000-Eintrag-Limit und automatischem Ablauf-Rückgewinnung. `Cachex.fetch/3` fasst gleichzeitige Fehlschläge für die gleiche IP in einen Resolver zusammen. Fehler werden nicht zwischengespeichert. Private und reservierte Adressen werden keinem Anbieter gesendet.

### Fehlende Seiten-Sprache

Das Dashboard zeigt **Nicht gemeldet**, wenn ein Event kein `sl` hat. Dies umfasst von älteren Tracker-Versionen gesammelte Ereignisse und Seiten ohne ein HTML `lang`-Attribut. Die Seiten-Sprache wird nicht aus Browser-Präferenzen oder der URL erschlossen. Historische Ereignisse behalten die Metadaten bei, die zum Zeitpunkt gesammelt wurden; neue Tracker-Versionen füllen sie nicht nach.

## Datenschutzmodell

- **Kein dauerhafter Cross-Session-Indikator.** Das SDK setzt keine Cookies und speichert nur eine pro-Tab Sitzungs-ID in `sessionStorage`, die der Browser beim Schließen leert.
- **Keine Fingerabdrücke.** Canvas-, WebGL-, Schriftart- und Audio-Fingerabdrücke werden nicht gesammelt. Der täglich rotierende Server-Hash bietet Eindeutigkeit ohne sie.
- **Keine Roh-Identifikatoren gespeichert.** IP und Benutzeragenten werden einmal gelesen, mit einem Server-Secret und einem täglichen Salz gehasht und dann verworfen.
- **Pro-Projekt-Bereich.** Der gleiche Browser auf zwei Projekten liefert irrelevante Besucher-IDs, sodass Besucher nicht zwischen Glossia-Kunden verfolgt werden können.
