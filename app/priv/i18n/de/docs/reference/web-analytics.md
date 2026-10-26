%{
  title: "Analytik-SDK",
  summary:
    "Die erhobenen Felder, der Events-Endpunkt und das Datenschutzmodell hinter der Glossia Webanalyse.",
  category: "Referenz",
  section: "analytics",
  order: 1
}
---

## Ereignisse-Endpunkt

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` bleibt für die Kompatibilität verfügbar. Das gehostete Skript leitet `/v1/collect` aus seinem eigenen Ursprung; Paketintegrationen sollten `endpoint` explizit festlegen.

Akzeptiert ein JSON-Ereignis vom `@glossia/web` SDK. Antwortet immer `202 Accepted`, auch für unbekannte Domains oder falsch formatierte Payloads, sodass das SDK niemals verrät, welche Projekte Analysen erfassen.

Das Projekt wird durch die Site-Domain gelöst, die der Snippet angibt. `d` ist maßgeblich; wenn es fehlt, greift der Server auf den Host von `u` (die Seiten-URL) und dann die Anfrage `Origin`/`Referer` zurück.

### Anfragekörper

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Site-Domain, die das Projekt identifiziert (z. B. `example.com`). Vom Browser-Bibliothek gesendet; Fallback-Auflösung siehe oben. |
| `n`   | string | Ereignisname. Standardwert: `pageview`.                          |
| `u`   | string | Seiten-URL (`location.href`).                                  |
| `r`   | string | Verweisquelle (`document.referrer`).                              |
| `l`   | string | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `sl`  | string | Tatsächliche Seitensprache (`document.documentElement.lang`). Leer, wenn nicht deklariert. |
| `al`  | string | Kommagetrennte Übersetzungssprachen aus `link[rel="alternate"][hreflang]`, ohne `x-default`. |
| `cl`  | string | Explizit gewählte Sprache, oder leer, wenn keine Auswahl beobachtet wurde. Das SDK normalisiert BCP 47-Tags und begrenzt die Eingabe auf 64 Zeichen. |
| `tz`  | string | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Bildschirmbreite in CSS-Pixeln.                                  |
| `sid` | string | Sitzungs-ID pro Tab (sessionStorage, beim Schließen geleert).       |

CORS ist erlaubt (`Access-Control-Allow-Origin: *`) , da der Endpunkt keine Berechtigungen akzeptiert.

## Explizite Sprachauswahl

`selectLanguage(language)` ist als benannter Export verfügbar, im Standard-SDK-Export und in `glossia` global der gehosteten Skripte. Rufen Sie es nach Initialisierung aus einem Benutzeraktions-Handler auf, bevor die Navigation stattfindet. Ungültige Sprach-Tags und Aufrufe vor Initialisierung werden ignoriert.

Die Methode sendet ein `language_selection`-Ereignis sofort. Sein `sl` beschreibt immer noch die aktuelle Seite, nicht das Ziel. Folgende Ereignisse enthalten die Wahl in `cl` bis eine weitere explizite Wahl sie ersetzt. Ohne beobachtete Auswahl ist `cl` leer. Die Wahl wird als `__glossia_selected_language` in gleichen Ursprungs, pro-Tab `sessionStorage` gespeichert; bei Speicherfehler wird sie nur im Arbeitsspeicher bis zum Entladen behalten.

Für Links ermöglicht `data-glossia-language="zh-Hans"` die delegierte Verfolgung von vertrauenswürdigen, unveränderten Primärklicks, einschließlich Tastatur-Aktivierung. Generierte Klicks, bereits abgebrochene Klicks, Downloads, cross-origin-Links und Links, die einem anderen Tab oder Frame dienen, werden ignoriert. Der Listener läuft in der Einfangphase, bevor Router navigieren, verhindert keine Navigation und behandelt zudem dynamisch eingefügte Links. Verwenden Sie entweder die Annotation oder die API für eine Aktion, nicht beides.

Dies ist ein vom Client gemeldetes Absichtssignal, kein Beweis, dass die Navigation erfolgreich war. URL-Änderungen, Weiterleitungen und HTML-Sprachänderungen werden nicht als Auswahl interpretiert. Die Auswahl überschreibt `l` oder `sl` nicht, oder ändert derzeit `has_locale_gap` oder Dashboard-Badges nicht.

## Von Server abgeleitete Felder

Diese werden beim Ingestion berechnet und serverseitig gespeichert. Der Roh-IP und User-Agent werden nie gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotiertes Hash von IP + UA + Projekt. Nicht über Tage hinweg verknüpfbar.  |
| `country_code`    | Cloudflare / GeoIP | ISO-3166-1-alpha-2-Code aus einem vertrauenswürdigen `CF-IPCountry`-Header oder dem konfigurierten IP-Geolokalisierungsadapter. Leer, wenn keiner ein Land bestimmt. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` oder `unknown`.        |
| `hostname`        | Seiten-URL      | Kleingeschriebener Host.                                                    |
| `pathname`        | Seiten-URL      | Pfad-Komponente.                                                     |
| `referrer_source` | Referrer      | Referrer-Host, mit voranstellendem `www.`/`m.` gestrichen.                        |
| `browser_language`| Sprachen     | Am besten bevorzugte normalisierte Region (z. B. `pt-BR`).                    |
| `served_locale`   | Seitensprache | Normalisierte `sl`, oder leer, wenn sie nicht gesammelt wurden. Zeilen mit leeren Seitenspracheneinträgen werden aus der Browser-Sprache-Aufschlüsselung ausgeschlossen. |
| `selected_locale` | Explizite Auswahl | Normalisierte `cl`, oder leer für fehlende, fehlerhafte oder zu große Eingabe. Getrennt von Browserpräferenz und Seitensprache gespeichert. |
| `has_locale_gap`  | Berechnet      | `1` vorhanden, wenn keine der bevorzugten Sprachen des Besuchers den Projektzielen, beworbenen Übersetzungen (`al`) oder der Seitensprache (`sl`) entspricht. Fehlende Präferenzen gelten nicht als Lücke. |

### Client-IP-Auflösung

Für Anfragen von einem privaten Ingress-Peer verwendet Glossia nginx’s überschriebenen `X-Real-IP`-Header, nicht den von der Ansammlung gesteuerten ersten Eintrag in `X-Forwarded-For`. Direkte öffentliche Verbindungen verwenden die Socket-Adresse. Auf Hetzner müssen sowohl der Lastenverteiler als auch nginx das PROXY-Protokoll aktivieren, sodass nginx die Besucheradresse statt der Lastenverteileradresse empfängt. Andere Reverse-Proxy müssen auch `X-Real-IP` mit einer authentifizierten Quelle überschreiben, nicht mit einem unbegrenzten eingehenden `X-Forwarded-For`-Header. Die Weiterleitungsheader-Politik des generischen Diagramms allein garantiert dies nicht. Private Pairs sind vertrauenswürdige Infrastruktur, daher direkten Pod-Zugang einschränken.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` ermöglicht `CF-Connecting-IP` die Überschreibung der kanonischen Adresse für Anfragen von einem privaten Ingress-Peer. Es ist **standardmäßig deaktiviert**, unabhängig vom Vertrauen des Länder-Headers. Aktivieren Sie es nur nachdem der Rand Cloudflare authentifiziert oder gefälschte Header entfernt, wenn sie Cloudflare umgehen. DNS-only-Deployments sollten ihn deaktiviert lassen. Diese Adresse prüft auch IP-Rate-Limits und das tägliche Besucher-Hash.

### Land-Auflösung

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` ermöglicht den `CF-IPCountry`-Snack-Verlauf. Es ist **stoly deaktiviert**. Aktivieren Sie es nur nachdem der Ursprung Cloudflare authentifiziert, keine Abstiege ankämpft, die Cloudflare umgehen, oder der In-Band unzuverlässige Exemplare des Headers entfernt. Cloudflares IP-Geolokalisierungs-Einstellung muss auch für den Sektor aktiviert sein. `CF-Connecting-IP`, `CF-Ray` und nginx’s `use-forwarded-headers` authentifizieren eine Anfrage nicht alleine.

Wenn Header-Vertrauen aktiviert ist, wird ein einzelner gültiger ISO-Ländercode sofort verwendet, ohne IP-Abfrage oder Cache-Zugriff. Der aktuelle Randwert hat immer Vorrang vor jeder auscacheierten Abfrage. Fehlende, duplizierte, fehlerhafte oder unbekante Codes, einschließlich Cloudflares `XX` (unbekannt) und `T1` (Tor)-Werte, fallen auf den konfigurierten Geolokalisierungsadapter zurück.

Ohne konfigurierte MaxMind-Datenbank verwenden Fallback-Suchanfragem `api.ipapi.is` dann `api.country.is` bei Scheitern der Hauptanfrage oder wenn kein bekanntes Land zurückgegeben wird. Jede Anfrage hat einen Verbindungs- und Antwort-Timeout von einer Sekunde ohne Wiederholungen. Erfолько Ergebnisse von beiden Anbietern werden von Cachex für 24 Stunden zwischengepuffert, mit einem limitierten Zählerarchiv von 100.000 Einträgen und automatischer Ablaufzeit-Bereinigung. `Cachex.fetch/3` kollabiert konsequente Missfälle für denselben IP zu einem Resolver. Fehlern wurden nicht zwischengepuffert. Private und Reservierte Adressen werden an keine Anbieter geschickt.

### Fehlende Seitensprache

Die Browser-Sprache-Aufschlüsselung übersieht Ereignisse ohne `sl`. Dies umfasst von älteren Verfolgern gesammelte Ereignisse und Seiten ohne HTML `lang`-Attribut. Diese Ereignisse tragen weiterhin zu eigenem Verkehr bei. Die Seitensprache wird nicht aus Browserpräferenzen oder der URL abgeleitet. Historische Ereignisse behalten die zum Zeitpunkt gesammelten Metadaten; neue Verfolger-Versionen füllen sie nicht nach.

## Datenschutzmodell

- **Kein beständiger Cross-Session-Identifikator.** Das SDK setzt keine Cookies und speichert nur eine Sitzungs-ID pro Tab und eine explizit gewählte Sprache in `sessionStorage`, die das Browser zum Löschen unsichert.
- **Kein Fingerprinting.** Canvas, WebGL, Font und Audio-Fingerabdrücke werden nicht gesammelt. Hash des Servers rotiert täglich.
- **Keine Roh-Identifikatoren bestehen.** IP und User-Agent werden nur einmal gelesen, mit einem Servergeheimnis und einem täglichен Salz verschlüsselt und dann verworfen.
- **Projetk-Scope.** Der gleiche Browser auf zwei Projekten ergibt unverbundene Besucher-IDs, so dass Besucher nicht zwischen Glossia-Kunden verfolgt werden können.
