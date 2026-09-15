%{
  title: "Socialbilder",
  summary: "Tägliche Dashboard-Vorschauen, Browser-Rendering, Speicher und Traffic-Limits.",
  category: "Referenz",
  order: 30
}
---
Die Dashboard-Seiten bewerben ein 1200 × 630 Bild durch [Open Graph](https://ogp.me/)
und Twitter-Großbild-Metadaten. Öffentliche Projekte enthalten ihren Namen, Sektion,
und hochgeladenes Logo. Öffentliche Konten erhalten eine Vorschau für die Sektion. Privat
Konten und persönliche Einstellungen verwenden das generische Glossia-Branding.

## Bildidentität und Lebensdauer

Der Bild-Digest enthält den angezeigten Inhalt, die Revision des Projektlogos, die Vorlage,
Stile, Schriften, Marken-Asset, Abhängigkeits-Lockfile und den aktuellen Tag in
[Koordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Das Ändern eines dieser Elemente erstellt eine neue Adresse. Das Sortieren der Attribute und das Signieren
um Mitternacht bleibt die vollständige Adresse den ganzen Tag stabil.

Das signierte Payload kann von einem Benutzer nicht geändert werden. Es ist zwei Tage gültig,
sondern nur das Payload des aktuellen Tages kann ein fehlendes Bild generieren. Gestern
gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu Object-Store-Schlüsseln.

Erfolgreiche Bilder werden unter gespeichert. `og/images/<digest>.jpg` im konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatiblen Bucket.
Nur eine explizite missing-object-Antwort startet die Generierung. Speicherfehler
gibt einen zum Caching ungeeigneten vorübergehenden Fehler zurück, ohne Chrome zu starten. Ein Upload muss
erfolgreich sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendering und Limits

Rendering verwendet Carta mit BrowseChrome, denselben Stack wie Tuists Bildrenderer.
Der überwachte Pool enthält zwei Browser. Jeder Rendervorgang hat eine 15-Sekunden-Frist;
jede Anwendungsinstanz erlaubt höchstens zwölf neue Rendervorgänge pro Minute.
Anfragen für gespeicherte Bilder verbrauchen diese Quote nicht.

Cachex kombiniert parallele Anfragen für dasselbe Bild und behält bis zu 100
bilder für fünf Minuten. Ein nicht blockierender PostgreSQL Advisory Lock verhindert
verschiedene Anwendungs-Replicas beim gleichzeitigen Rendern desselben Bildes.
Andere Replikate erhalten einen vorübergehenden Fehler und können es erneut versuchen, sobald das Objekt existiert.

Die Vorlage kombiniert ein Noora-Sektion-Abzeichen mit dem warmen Hintergrund von Glossia, Serif
Überschrift, Farbverlauf-Akzent und schlichter Footer. Source Serif 4 und Inter sind
lokal eingebunden, sodass Vorschauen nicht von einem Schriftarten-Service abhängig sind. Schriftarten und Raster
Logos werden eingebettet. Die Content-Security-Policy des Dokuments blockt Skripte und
externe Ressourcen. Logos werden nur vom Avatar-Speicher der Anwendung geladen
Präfix und sind auf fünf Millionen Bytes beschränkt, entsprechend den Projekthochladungen

## Antwortverhalten

| Ergebnis | Status | Cache-Verhalten |
|---|---|---|
| Gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, ein Tag, unveränderlich |
| Ungültige, abgelaufene oder veränderte Signatur | 404 | Kein Speicher |
| Gesterns Bild fehlt im Speicher | 404 | Kein Speicher |
| Browser beschäftigt, Rendering-Fehler oder Speicher nicht verfügbar | 503 | Kein Speicher; erneut versuchen nach 60 Sekunden |
| Ursprunganfrage-Limit überschritten | 429 | Kein Speicher; Wiederholintervall in der Antwort |

Der Ursprung erlaubt dreißig Anfragen pro Minute pro Client-Adresse, einschließlich
ungültiger Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich verifizierter Crawler. Es
erlaubt zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Überschreitet man das Limit, werden Anfragen für zehn Sekunden blockiert. Die allgemeinen
Die Challenge-Regeln für öffentliche Seiten schließen diesen Pfad aus, sodass Bild-Crawler niemals müssen
eine Browser-Challenge lösen.

Cloudflare [Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
cacht `.jpg` Antworten und beachtet Origin-Cache-Header. Bewahren Sie die signierte Abfrage
zeichenfolge im Standard-Cache-Schlüssel. Verwenden Sie keine überschreibende Cache-Dauer, die
Fehler-Antworten cacht oder ignoriert `no-store`. Die deterministische Signatur vermeidet
einen Cache-Eintrag pro Seitenanfrage.

Bereitstellen Sie die Infrastrukturressource parallel zur Anwendung. Stellen Sie sicher, dass der Ursprung
ist nur über den vertrauenswürdigen Ingress erreichbar, da weitergeleitete Client-Adressen
werden vom bestehenden Request-Limiter vertraut. Der Browser-Pool und das Render-Budget
begrenzen auch verteilte Cache-Misses und direkte Ursprungsanfragen.

## Lokale Konfiguration

Festlegen `GLOSSIA_OG_IMAGES=true` um den Browser-Pool in der Entwicklung zu aktivieren. Installieren
Google Chrome oder Chromium verwenden, um Assets mit `mix assets.build`, und konfigurieren
die bestehenden Umgebungsvariablen für Objektspeicher:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ausführen `mix ecto.setup` und `mix phx.server`. Sobald der Speicher konfiguriert ist, geben Startdaten
dem öffentlichen `dev/glossia` Projekt ein Logo. Prüfen Sie die `og:image` Metadaten von einem
Dashboard-Seite, um die signierte Bildadresse zu erhalten.