%{
  title: "Analytik SDK",
  summary:
    "Die gesammelten Felder, der Events-Endpoint und das Datenschutzmodell hinter der Glossia-Webanalytik.",
  category: "Referenz",
  section: "analytics",
  order: 1
}
---

## ## Ereignis-Endpunkt

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` bleibt für Kompatibilität verfügbar. Das gehostete Skript ableitet `/v1/collect` aus der eigenen Ursprungsdomain; Paket-Integrationen müssen `endpoint` explizit setzen.

Entgegnet ein JSON-Ereignis von der `@glossia/web` SDK. Reagiert immer mit `202 Accepted`, auch bei unbekannten Domänen oder falschen Payloads, sodass die SDK niemals verrät, welche Projekte Analysdaten erfassen.

Das Projekt wird durch die Site-Domain aufgelöst, die das Fragment erklärt. `d` ist autoritativ; fehlt es, fällt der Server auf den Host von `u` (die Seiten-URL) sowie die Anfragen `Origin`/`Referer` zurück.

### Anforderungsbody

| Feld | Typ   | Beschreibung                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | Zeichenkette | Site-Domain zur Kennung des Projekts (z. B. `example.com`). Vom Browser-Bibliothek gesendet; Fallback-Auflösung wird oben beschrieben. |
| `n`   | Zeichenkette | Ereignisname. Standardmäßig `pageview`.                          |
| `u`   | Zeichenkette | Seiten-URL (`location.href`).                                  |
| `r`   | Zeichenkette | Referer (`document.referrer`).                              |
| `l`   | Zeichenkette | Browser-Sprachen (`navigator.languages.join(",")`).         |
| `sl`  | Zeichenkette | Tatsächliche Seitensprache (`document.documentElement.lang`). Leer, wenn nicht deklariert. |
| `al`  | Zeichenkette | Komma-separierte Übersetzungssprachen von `link[rel="alternate"][hreflang]`, ausgeklammert `x-default`. |
| `cl`  | Zeichenkette | Explizit gewählte Sprache oder leer, wenn keine Auswahl beobachtet wurde. Die SDK normalisiert BCP 47-Tags und begrenzt die Eingabe auf 64 Zeichen. |
| `tz`  | Zeichenkette | IANA-Zeitzone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | Zahl | Bildschirmbreite in CSS-Pixel.                                  |
| `sid` | Zeichenkette | Sitzungs-ID pro Tab (sessionStorage, gelöscht bei Schließen).       |

CORS ist offen (`Access-Control-Allow-Origin: *`), da das Endpunkt keine Authentifizierungsdaten akzeptiert.

## Explizite Sprachauswahl

`selectLanguage(language)` ist als benannter Export verfügbar, im Standard-SDK-Export und am globalen `glossia` des gehosteten Skripts. Rufen Sie es nach Initialisierung vom einen Handler für Benutzeraktionen auf, bevor Sie navigieren. Ungültige Sprach-Tags und Aufrufe vor Initialisierung werden ignoriert.

Die Methode sendet ein `language_selection`-Ereignis sofort. Der `sl` beschreibt weiterhin die aktuelle Seite, nicht das Ziel. Folgende Ereignisse fassen die Auswahl im `cl` auf, bis eine weitere explizite Auswahl sie ersetzt. Ohne beobachtete Auswahl ist `cl` leer. Die Auswahl wird als `__glossia_selected_language` im same-origin, pro-Tab-`sessionStorage` gespeichert; bei Speicherungsfehlern wird es nur im Speicher beibehalten, bis Entladen.

Für Links ermöglicht `data-glossia-language="zh-Hans"` das delegierte Tracking von vertrauenswürdigen, unveränderten Primärklicks, einschließlich Tastaturaktivierung. Programmierte Klicks, bereits abgebrochene Klicks, Downloads, Cross-Origin-Links und Links, die ein anderes Tab oder Frame ins Ziel, werden ignoriert. Der Listener läuft in der Einfangphase vor der Router-Navigation, verhindert Navigation nicht, und behandelt auch dynamisch eingefügte Links. Verwenden Sie entweder die Annotation oder die API für eine Aktion, nicht beide.

Dies ist ein vom Client gemeldeter Intent-Signal, kein Beweis für erfolgreiche Navigation. URL-Änderungen, Umleitungen und Sprachänderungen von HTML werden nicht als Auswahl gewertet. Die Auswahl überschreibt `l` oder `sl` nicht. Eine gültige Auswahl hat Vorrang vor Browser-Einstellungen nur bei Berechnung von `has_locale_gap`: Die gewählte Sprache muss einem Projektziel, einer beworbenen Übersetzung (`al`) oder der tatsächlichen Seitensprache (`sl`) entsprechen. Die Auswahl selbst ist kein Beleg für Verfügbarkeit. Die Übereinstimmung nutzt normalisierte exakte-oder-basis-Sprache-Übereinstimmungen, wie bei Browser-Einstellungen.

Zum Beispiel hat ein Besucher, der Japanisch bevorzugt und explizit verfügbares Englisch wählt, keine Lücke. Ein Besucher, der Englisch bevorzugt und nicht verfügbares Japanisch wählt, hat immer noch eine Lücke, selbst auf einer englischen Seite. Ein Auswahl-Ereignis, das vor Navigation gesendet wurde, behält die `sl` der aktuellen Seite; die Ziel-Sprache kann über Projekt-Ziele oder `al` erkannt werden, ohne anzunehmen, Navigation erfolgreich war.

Fehlende, falschformatierte oder zu große Wahlen passen sich Browser-Einstellungen an. Wenn weder eine Auswahl noch Browser-Einstellungen bekannt sind, besteht keine Lücke. Dashboard-Gesamtsummen und Badges lesen die gespeicherte pro-Ereignis-Flagge. Historische Flaggen, einschließlich derer, die vor Auswahl gesammelt wurden und die die Lücken-Berechnung beeinflussten, werden nicht neu berechnet: Historische beworbene Übersetzungen und vollständige Browser-Einstellungen werden nicht gespeichert.

## Server-abgeleitete Felder

Diese werden bei der Erfassung berechnet und serverseitig gespeichert. Die Roh-IP und User-Agent werden niemals gespeichert.

| Feld             | Quelle        | Beschreibung                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Täglich rotierter Hash von IP + User-Agent + Projekt. Nicht über Tage hinweg verknüpfbare.  |
| `country_code`    | Cloudflare / GeoIP | ISO 3166-1 alpha-2-Zeichenfolge aus einem vertrauenswürdigen `CF-IPCountry`-Header oder dem konfigurierten IP-Geolokationsadapter. Leer, wenn keiner einen Landcode ermittelt. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` oder `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` oder `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` oder `unknown`.        |
| `hostname`        | Seiten-URL      | Kleingeschriebener Host.                                                    |
| `pathname`        | Seiten-URL      | Pfadkomponente.                                                     |
| `referrer_source` | Referer      | Referer-Host, führende `www.`/`m.` gestrichen.                        |
| `browser_language`| Sprachen     | Am meisten bevorzugte normalisierte Locale (z. B. `pt-BR`).                    |
| `served_locale`   | Seitensprache | Normalisiertes `sl` oder leer, wenn es nicht gesammelt wurde. Zeilen mit einer leeren Seitensprache werden im Browser-Sprachenaustritt nicht berücksichtigt. |
| `selected_locale` | Explizite Wahl | Normalisiertes `cl` oder leer für fehlende, falschformatierte oder zu große Eingabe. Getrennt von Browserpräferenz und Seitensprache gespeichert. |
| `has_locale_gap`  | Berechnet      | `1` wenn eine gültige explizite Wahl keine Übereinstimmung unter Projektzielen, beworbenen Übersetzungen (`al`) oder Seitensprache (`sl`) aufweist. Ohne gültige Wahl `1` nur, wenn Browserpräferenzen nicht leer sind und keine übereinstimmen. |

### Client-IP-Auflösung

Für Anfragen von einem privaten Ingress-Peer verwendet Glossia den von nginx überschriebenen `X-Real-IP`-Header, nicht den vom caller gesteuerten ersten Eintrag in `X-Forwarded-For`. Direkte öffentliche Verbindungen verwenden die Socket-Adresse. Auf Hetzner müssen sowohl der Load Balancer als auch nginx das PROXY-Protokoll aktivieren, damit nginx die Besucheradresse statt der Load-Balancer-Adresse erhält. Andere Reverse-Proxy müssen auch `X-Real-IP` mit einer authentifizierten Quelle überschreiben, nicht einen uneingeschränkten ankommenden `X-Forwarded-For`-Header. Die generische Richtlinie für Forwarded-Header allein garantiert dies nicht. Private Peers sind vertrauenswürdige Infrastruktur, daher direkten Pod-Zugang beschränken.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` erlaubt `CF-Connecting-IP` die Überschreibung der kanonischen Adresse für Anfragen von einem privaten Ingress-Peer. Es ist **standardmäßig deaktiviert**, unabhängig vom Vertrauen des Länder-Headers. Aktivieren Sie es nur, nachdem die Edge Cloudflare authentifiziert oder gefälschte Header bei umgehenden Cloudflare-Anfragen gestrichen wurden. DNS-Only-Implementierungen sollten es deaktiviert lassen. Diese Adresse schließt auch IP-Ratenbeschränkungen und die tägliche Besucher-Hash ein.

### Land-Auflösung

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` ermöglicht den `CF-IPCountry`-Schnellweg. Es ist **standardmäßig deaktiviert**. Aktivieren Sie es nur, nachdem die Quelle Cloudflare authentifiziert, Anfragen anordnet, die umgehen Cloudflare, oder der Ingress Nichtvertrauenswürdige Kopien des Headers entfernt. Cloudflare IP-Geolokationseinstellung muss auch für die Zone aktiviert sein. `CF-Connecting-IP`, `CF-Ray` und ngnix `use-forwarded-headers` authentifizieren eine Anfrage nicht allein.

Wenn Header-Vertrauen aktiv ist, wird ein einziger gültiger ISO-Landcode sofort verwendet, ohne IP-Lookup oder Cache-Zugriff. Der aktuelle Edge-Wert hat Vorrang vor jedem zwischengespeicherten Lookup. Fehlende, duplizierte, falschformatierte oder unbekannte Codes, einschließlich Cloudflares `XX` (unbekannt) und `T1` (Tor)-Werte, wechseln auf den konfigurierten Geolokationsadapter zurück.

Ohne konfigurierte MaxMind-Datenbank wechseln Fallback-Lookups zu `api.ipapi.is` und dann zu `api.country.is`, wenn die primäre Anfrage fehlschlägt oder kein erkennbares Land zurückgibt. Jede Anfrage hat eine einsekundige Verbindungs- und Antwortzeitüberschreitung ohne Wiederaufrufe. Erfolgreiche Ergebnisse von beiden Anbietern werden für 24 Stunden durch Cachex zwischengespeichert, mit einem 100.000-Einträge-planmäßigen Größenlimit und automatischem Ablauf-Wiederherstellung. `Cachex.fetch/3` konsolidiert gleichzeitig fehlgeschlagene Anfragen für denselben IP zu einem Resolver. Fehlschläge werden nicht zwischengespeichert. Private und reservierte Adressen werden an keinen Anbieter gesendet.

### Fehlende Seitensprache

Die Browser-Sprach洩auerraum schließt Veranstaltungen ohne `sl` aus. Dies schließt Veranstaltungen der vergangenen Tracker-Versionen und Seiten ohne einen HTML `lang`-Attribut ein. Diese Veranstaltungen tragen weiterhin zum Gesamtverkehr bei. Der Seitensprache wird nicht aus Browserpräferenzen oder der URL abgeleitet. Historische Veranstaltungen behalten die zur Zeit gesammelten Metadaten; neue Tracker-Versionen befüllen sie nicht zurück.

## Datenschutzmodell

- **Kein anhaltender Cross-Sitzungs-Identifikator.** Das SDK setzt keine Cookies und speichert nur eine pro-tab Session-ID und eine explizit gewählte Sprache in `sessionStorage`., die der Browser beim Schließen löscht.
- **Kein Fingerprinting.** Canvas-, WebGL-, Schriftart- und Audio-Fingerabdrücke werden nicht gesammelt. Der tägliche rotierte Server-Hash bietet Einzigartigkeiten ohne diese.
- **Keine rohen Identifikatoren dauerhaft.** IP und User-Agent werden einmal gelesen, mit einem Server-Secret und einem täglichen Salzzahl verschlüsselt und dann verworfen.
- **Projektbegrenzung.** Der gleiche Browser auf zwei Projekten führt zu nicht miteinander verknüpften Besucher-IDs, sodass Besucher nicht über Glossia-Kunden hinweg verfolgt werden können.
