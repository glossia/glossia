%{
  title: "Social-Media-Bilder",
  summary: "Tägliche Dashboard-Vorschauen, Browser-Rendering, Speicher- und Datenlimits.",
  category: "Referenz",
  order: 30
}
---
Dashboard-Seiten werben mit einem 1200 × 630-Bild über [Open Graph](https://ogp.me/)
und Twitter-Großbild-Metadaten. Öffentliche Projekte enthalten ihren Namen, Bereich,
und hochgeladenes Logo. Öffentliche Konten erhalten eine bereichsspezifische Vorschau. Private
Konten und persönliche Einstellungen verwenden generisches Glossia-Branding.

## Bild-Identität und Lebensdauer

Der Bild-Digest enthält den angezeigten Inhalt, die Projektlogo-Revision, das Template,
Stile, Schriften, Marken-Asset, Abhängigkeits-Lockfile und aktueller Tag in
[Koordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Das Verändern eines dieser Werte erstellt eine neue Adresse. Das Sortieren der Attribute und das Signieren
um Mitternacht bleibt die vollständige Adresse den gesamten Tag über stabil.

Der signierte Payload kann von einem Besucher nicht verändert werden. Er ist zwei Tage gültig,
aber nur der Payload des aktuellen Tages darf ein fehlendes Bild generieren. Gestern
gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu Object-Store-Schlüsseln.

Erfolgreiche Bilder werden gespeichert unter `og/images/<digest>.jpg` in der konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatiblen Bucket.
Nur eine explizite missing-object-Anwort startet die Generierung. Speicherfehler
geben einen nicht zwischenspeicherbaren vorübergehenden Fehler, ohne Chrome zu starten. Ein Upload muss
erfolgreich sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendering und Limits

Rendering nutzt Carta mit BrowseChrome, den gleichen Stack wie den Bild-Renderer von Tuist.
Der überwachte Pool enthält zwei Browser. Jedes Rendern hat eine 15-Sekunden-Frist;
Jede Anwendungsinstanz erlaubt maximal zwölf neue Rendern pro Minute.
Anfragen für gespeicherte Bilder verbrauchen dieses Kontingent nicht.

Cachex kombiniert gleichzeitige Anfragen für das gleiche Bild und behält bis zu 100
Bilder für fünf Minuten. Ein nicht blockierender PostgreSQL advisory lock verhindert
verschiedene Anwendungsreplikate von der gleichzeitigen Darstellung desselben Bildes.
Andere Replikate erhalten einen vorübergehenden Fehler und können es erneut versuchen, sobald das Objekt vorhanden ist.

Das Template verbindet ein Noora-Sektion-Abzeichen mit dem warmen Hintergrund von Glossia, Serif
Überschrift, Gradient-Akzent und dezente Fußzeile. Source Serif 4 und Inter sind
lokal gebündelt, sodass Vorschauen keinen Font-Service benötigen. Schriften und Raster
Logos sind eingebettet. Die Content-Security-Policy des Dokuments blockiert Skripte und
externe Ressourcen. Logos werden ausschließlich aus dem Avatar-Speicher der Anwendung geladen.
Präfix und sind auf fünf Millionen Bytes begrenzt, entsprechend den Projekt-Uploads.

## Antwortverhalten

| Ergebnis | Status | Cache-Verhalten |
|---|---|---|
| Ein gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, einen Tag, unveränderlich |
| Ungültige, abgelaufene oder veränderte Signatur | 404 | Kein Speicher |
| Bild vom Vortag fehlt im Speicher | 404 | Kein Speicher |
| Browser beschäftigt, Render-Fehler oder Speicher nicht verfügbar | 503 | Kein Speicher; erneut versuchen nach 60 Sekunden |
| Origin-Anfragen-Limit überschritten | 429 | Kein Speicher; Wiederholungsintervall in Antwort |

Der Origin erlaubt 30 Anfragen pro Minute pro Client-Adresse, einschließlich
ungültige Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich verifizierter Crawler. Es
ermöglicht zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Das Überschreiten des Limits blockiert Anfragen für zehn Sekunden. Die allgemeinen
Die Public-Page-Challenge-Regeln schließen diesen Pfad aus, sodass Bild-Crawler nie müssen
eine Browser-Challenge lösen.

von Cloudflare [das Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
speichert `.jpg` Antworten und beachtet Origin-Cache-Header. Behalte den signierten
String im Standard-Cache-Schlüssel. Wende keine überschreibende Cache-Dauer an, die
Fehler-Antworten speichert oder ignoriert `no-store`. Die deterministische Signatur vermeidet
einen Cache-Eintrag pro Seitenanfrage.

Deployieren Sie die Infrastrukturressource parallel zur Anwendung. Stellen Sie sicher, dass der Origin
ist nur über das vertraute Ingress erreichbar, da weitergegebene Client-Adressen
durch den bestehenden Request-Limiter vertraut werden. Der Browser-Pool und das Render-Budget
begrenzen ebenfalls verteilte Misses und direkte Origin-Anfragen.

## Lokale Konfiguration

Setzen `GLOSSIA_OG_IMAGES=true` um den Browser-Pool in der Entwicklung zu aktivieren. Installieren Sie
Google Chrome oder Chromium, erstellen Sie Assets mit `mix assets.build`, und konfigurieren
die vorhandenen Objekt-Speicher-Umgebungsvariablen:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ausführen `mix ecto.setup` und `mix phx.server`. Bei konfigurierter Speicherung geben Startwerte
das öffentliche `dev/glossia` Projekt ein Logo. Überprüfen Sie die `og:image` Metadaten auf eine
Dashboard-Seite zum Abrufen der Adresse des signierten Bildes.