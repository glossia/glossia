%{
  title: "Social-Media-Bilder",
  summary: "Tägliche Dashboard-Vorschauen, Browser-Rendering, Speicher und Datenverkehrslimits.",
  category: "Referenz",
  order: 30
}
---
Dashboard-Seiten bewerben ein 1200 × 630-Bild über [Open Graph](https://ogp.me/)
und Twitter-Großbild-Metadaten. Öffentliche Projekte beinhalten ihren Namen, Abschnitt,
und hochgeladenes Logo. Öffentliche Konten erhalten eine abschnittsspezifische Vorschau. Private
Konten und persönliche Einstellungen verwenden generische Glossia-Branding.

## Bildidentität und Lebensdauer

Der Bild-Digest enthält den angezeigten Inhalt, Projekt-Logo-Revision, Vorlage,
Stile, Schriften, Marken-Asset, Abhängigkeits-Lockfile, und aktueller Tag in
[koordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Änderung eines dieser Werte erstellt eine neue Adresse. Die Sortierung der Attribute und das Signieren
bei Mitternacht bleibt die vollständige Adresse den ganzen Tag über stabil.

Die signierte Last darf nicht von einem Besucher geändert werden. Sie ist zwei Tage lang gültig,
aber nur die Last des aktuellen Tages darf ein fehlendes Bild generieren. gestern
gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu Objektspeicher-Schlüsseln.

Erfolgreiche Bilder werden gespeichert unter `og/images/<digest>.jpg` in der konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatible Bucket.
Nur eine explizite Missing-Object-Antwort startet die Generierung. Speicherfehler
geben einen nicht zwischenspeicherbaren vorübergehenden Fehler zurück, ohne Chrome zu starten. Ein Upload muss
erfolgreich sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendering und Grenzenwerte

Rendering verwendet Carta mit BrowseChrome, denselben Stapel wie der Bildrenderer von Tuist.
Der überwachte Pool enthält zwei Browser. Jedes Rendering hat eine 15-Sekunden-Frist;
jede Anwendungsinstanz erlaubt höchstens zwölf neue Renderings pro Minute.
Anfragen für gespeicherte Bilder verbrauchen diese Quote nicht.

Cachex kombiniert gleichzeitige Anfragen für das gleiche Bild und behält bis zu 100
Bilder für fünf Minuten. Ein blockfreier PostgreSQL Advisory Lock verhindert
verschiedene Anwendungsrepliken, dasselbe Bild gleichzeitig zu rendern.
Weitere Repliken erhalten einen vorübergehenden Fehler und können erneut versuchen, sobald das Objekt existiert.

Die Vorlage verbindet ein Noora-Abschnitt-Abzeichen mit Glossias warmem Hintergrund, Serif
Überschrift, Gradientakzent und dezenter Fußbereich. Source Serif 4 und Inter sind
lokal gebündelt, sodass Vorschauen nicht von einem Font-Service abhängen. Schriften und Raster
Logos sind eingebettet. Die Content-Security-Policy des Dokuments blockiert Skripte und
externen Ressourcen. Logos werden nur vom Avatar-Speicher der Anwendung geladen
Präfix und sind auf fünf Millionen Bytes begrenzt, entsprechend den Projekt-Uploads.

## Antwortverhalten

| Ergebnis | Status | Cacheverhalten |
|---|---|---|
| Gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, ein Tag, unveränderlich |
| Ungültige, abgelaufene oder geänderte Signatur | 404 | Keine Persistierung |
| Gestriges Bild fehlt im Speicher | 404 | Keine Persistierung |
| Browser beschäftigt, Renderfehler oder Speicher nicht verfügbar | 503 | Keine Persistierung; Nachversuch nach 60 Sekunden |
| Ursprungsanfrage-Limit überschritten | 429 | Keine Persistierung; Wiederholungsintervall in der Antwort |

Der Ursprung erlaubt dreißig Anfragen pro Minute pro Client-Adresse, einschließlich
ungültige Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich verifizierter Crawler. Es
erlaubt zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Das Überschreiten des Limits blockiert Anfragen für zehn Sekunden. Die allgemeine
Die Public-Page-Challenge-Regeln schließen diesen Pfad aus, sodass Bild-Crawler dies nie brauchen, um
eine Browser-Challenge zu lösen.

von Cloudflare [Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
zwischenspeichert `.jpg` Antworten und beachtet Ursprung-Cache-Header. Behalten Sie die signierte Anfrage-
Zeichenkette im Standard-Cache-Schlüssel. Verwenden Sie keine überschreibende Cache-Dauer, die
fehlerhafte Antworten zwischenspeichert oder ignoriert `no-store`. Die deterministische Signatur vermeidet
ein Cache-Eintrag pro Seitenanfrage.

Bereitstellen Sie die Infrastrukturressource neben der Anwendung. Stellen Sie sicher, dass der Ursprung
ist nur über den vertrauenswürdigen Ingress erreichbar, da weitergeleitete Client-Adressen
vom bestehenden Request-Limiter vertrauenswürdig sind. Der Browser-Pool und das Rendering-Budget
begrenzen zudem verteilte Misses und direkte Ursprungsanfragen.

## Lokale Konfiguration

Festlegen `GLOSSIA_OG_IMAGES=true` um den Browser-Pool in der Entwicklung zu aktivieren. Installieren
Google Chrome oder Chromium, erstellen Sie Assets mit `mix assets.build`, und konfigurieren
die vorhandenen object-storage-Umgebungsvariablen:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Run `mix ecto.setup` und `mix phx.server`. Mit konfigurierter Speicherung geben Seeds
das öffentliche `dev/glossia` Projekt ein Logo. Überprüfen Sie `og:image` Metadaten zu einem
Dashboard-Seite zum Abrufen der signierten Bildadresse.