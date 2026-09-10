%{
  title: "Bilder für soziale Medien",
  summary: "Tägliche Dashboard-Vorschauen, Browserdarstellung, Speicher und Datenlimits.",
  category: "Referenz",
  order: 30
}
---
Dashboard-seiten bewerben ein 1200 × 630 Bild über [Open Graph](https://ogp.me/)
und Twitter-Großbild-Metadaten. Öffentliche Projekte beinhalten ihren Namen, Abschnitt,
und hochgeladenes Logo. Öffentliche Konten erhalten eine abschnittsspezifische Vorschau. Privat
Konten und persönliche Einstellungen verwenden generische Glossia-Markenalien.

## Bildidentität und Lebensdauer

Der Bild-Digest enthält den angezeigten Inhalt, Projektlogo-Revision, Vorlage,
Stile, Schriftarten, Marken-Asset, Abhängigkeits-Lockdatei, und aktuellen Tag in
[Koordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Das Ändern eines dieser Werte erzeugt eine neue Adresse. Das Sortieren der Attribute und das Signieren
um Mitternacht bleibt die vollständige Adresse den ganzen Tag über stabil.

Die unterzeichnete Nutzlast kann nicht von einem Besucher geändert werden. Sie ist zwei Tage gültig,
aber nur die Nutzlast des aktuellen Tages kann ein fehlendes Bild erzeugen. Gestern
Gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu Objektspeicher-Schlüsseln.

Erfolgreiche Bilder werden unter gespeichert. `og/images/<digest>.jpg` in dem konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatiblen Bucket.
Nur eine explizite fehlende-Objekt-Antwort startet die Generierung. Speicherfehler
gibt einen nicht zwischenspeicherbaren vorübergehenden Fehler zurück, ohne Chrome zu starten. Ein Upload muss
erfolgreich abgeschlossen sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendering und Limits

Rendering verwendet Carta mit BrowseChrome, den gleichen Stack wie der Tuist-Image-Renderer.
Der überwachte Pool enthält zwei Browser. Jeder Render hat eine 15-Sekunden-Frist;
Jede Anwendungsinstanz erlaubt maximal zwölf neue Renderings pro Minute.
Anfragen für gespeicherte Bilder verbrauchen dieses Kontingent nicht.

Cachex kombiniert gleichzeitige Anfragen für dasselbe Bild und behält bis zu 100
Bilder für fünf Minuten. Eine nicht blockierende PostgreSQL-Advisory-Sperre verhindert
dass verschiedene Anwendungsinstanzen gleichzeitig dasselbe Bild rendern.
Andere Instanzen erhalten einen vorübergehenden Fehler und können erneut versuchen, sobald das Objekt existiert.

Die Vorlage kombiniert ein Noora-Abschnittsabzeichen mit dem warmen Hintergrund von Glossia, Serif.
Überschrift, Gradientakzent und schlichte Fußzeile. Source Serif 4 und Inter werden
lokal eingebunden, damit Vorschauen nicht von einem Font-Service abhängen. Schriftarten und Raster
Logos sind eingebettet. Die Content-Security-Policy des Dokuments blockiert Skripte und
externe Ressourcen. Logos werden nur aus dem Avatar-Speicher der Anwendung geladen
Prefix und sind auf fünf Millionen Bytes begrenzt, entsprechend den Projekt-Uploads.

## Antwortverhalten

| Ergebnis | Status | Cache-Verhalten |
|---|---|---|
| Gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, ein Tag, unveränderlich |
| Ungültige, abgelaufene oder geänderte Signatur | 404 | Kein Speicher |
| Bild vom Vortag nicht im Speicher vorhanden | 404 | Kein Speicher |
| Browser beschäftigt, Darstellungsfehler oder Speicher nicht verfügbar | 503 | Kein Speicher; Wiederversuch nach 60 Sekunden |
| Erlaubnisgrenze für Origin-Anfragen überschritten | 429 | Kein Speicher; Wiederholungsintervall in der Antwort |

Der Origin gestattet dreißig Anfragen pro Minute pro Client-Adresse, einschließlich
ungültige Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich überprüfter Crawler. Es
erlaubt zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Die Überschreitung des Limits blockiert Anfragen für zehn Sekunden. Das allgemeine
Die Herausforderungsregeln der öffentlichen Seite schließen diesen Pfad aus, sodass Bild-Crawler dies nie tun müssen
eine Browser-Herausforderung lösen.

von Cloudflare [Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
speichert `.jpg` Antworten und respektieren Sie Origin-Cache-Header. Bewahren Sie die signierte Abfrage
Zeichenkette im Standard-Cache-Schlüssel. Verwenden Sie keine Cache-Dauer an, die
Fehlerantworten speichert oder ignoriert `no-store`. Die deterministische Signatur vermeidet
einen Cache-Eintrag pro Seitenanfrage.

Bereitstellen Sie die Infrastrukturressource neben der Anwendung. Stellen Sie sicher, dass der Origin
nur über den vertrauenswürdigen Ingress erreichbar ist, da weitergeleitete Client-Adressen
vom bestehenden Request-Limiter vertraut werden. Der Browser-Pool und das Renderbudget
begrenzen auch verteilte Fehlschläge und Direkt-Origin-Anfragen.

## Lokale Konfiguration

Setzen Sie `GLOSSIA_OG_IMAGES=true` um den Browser-Pool in der Entwicklung zu aktivieren. Installieren Sie
Google Chrome oder Chromium, erstellen Sie Assets mit. `mix assets.build`, und konfigurieren
die vorhandenen object-storage-Umgebungsvariablen:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Starten `mix ecto.setup` und `mix phx.server`. Mit konfiguriertem Speicher geben Seeds
das öffentliche `dev/glossia` Projekt ein Logo. Überprüfen Sie das `og:image` Metadaten zu einem
Dashboardseite zum Abrufen der signierten Bildadresse.