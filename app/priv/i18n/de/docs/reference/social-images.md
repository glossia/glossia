%{
  title: "Soziale Bilder",
  summary: "Tägliche Dashboard-Vorschauen, Browser-Rendering, Speicher und Datenverkehrslimits.",
  category: "Referenz",
  order: 30
}
---
Dashboard-Seiten werben mit einem 1200 × 630 Bild über [Open Graph](https://ogp.me/)
und Twitter-Großbild-Metadaten. Öffentliche Projekte enthalten ihren Namen, ihren Abschnitt,
und hochgeladenes Logo. Öffentliche Konten erhalten eine abschnittsspezifische Vorschau. Privat
Konten und persönliche Einstellungen nutzen das generische Glossia-Branding.

## Bildidentität und Lebensdauer

Der Bild-Digest beinhaltet den angezeigten Inhalt, die Projektlogo-Revision, das Template,
Stile, Schriftarten, Marken-Asset, Dependency Lockfile und aktuellem Tag in
[Coordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Das Ändern eines dieser erstellt eine neue Adresse. Das Sortieren der Attribute und Signieren
um Mitternacht die vollständige Adresse den ganzen Tag über stabil hält.

Das signierte Payload kann von einem Besucher nicht geändert werden. Es ist für zwei Tage gültig,
aber nur das Payload des aktuellen Tages kann ein fehlendes Bild generieren. Gestern
gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu Objekt-Speicher-Schlüsseln.

Erfolgreiche Bilder werden unter gespeichert `og/images/<digest>.jpg` in der konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatiblen Bucket.
Nur eine explizite Antwort auf fehlendes Objekt startet die Generierung. Speicherfehler
geben eine nicht zwischenspeicherbare vorübergehende Fehlermeldung zurück, ohne Chrome zu starten. Ein Upload muss
erfolgreich sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendern und Begrenzungen

Das Rendern verwendet Carta mit BrowseChrome, denselben Stack wie Tuists Bild-Renderer.
Der überwachte Pool enthält zwei Browser. Jeder Render hat eine 15-Sekunden-Frist;
jede Anwendungsinstanz erlaubt maximal zwölf neue Renders pro Minute.
Anfragen für gespeicherte Bilder verbrauchen dieses Kontingent nicht.

Cachex kombiniert gleichzeitige Anfragen für dasselbe Bild und speichert bis zu 100
Bilder für fünf Minuten. Ein nicht-blockierender PostgreSQL Advisory-Lock verhindert
verschiedene Anwendungsreplikate, dasselbe Bild gleichzeitig zu rendern.
Andere Replikate erhalten einen vorübergehenden Fehler und können es erneut versuchen, sobald das Objekt existiert.

Die Vorlage kombiniert ein Noora-Sektions-Badge mit dem warmen Hintergrund von Glossia, Serif
Überschrift, Gradient-Akzent und dezentaler Footer. Source Serif 4 und Inter sind
lokal eingebunden, sodass Vorschauen nicht von einem Font-Service abhängig sind. Schriften und Raster
Logos sind eingebettet. Die Content-Security-Policy des Dokuments blockiert Skripte und
externen Ressourcen. Logos werden nur aus dem Avatar-Speicher der Anwendung
Präfix und sind auf fünf Millionen Bytes begrenzt, entsprechend den Projekt-Uploads.

## Antwortverhalten

| Ergebnis | Status | Cacheverhalten |
|---|---|---|
| Gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, einen Tag, unveränderlich |
| Ungültige, abgelaufene oder veränderte Signatur | 404 | Kein Speicher |
| Bild von gestern fehlt im Speicher | 404 | Kein Speicher |
| Browser ausgelastet, Rendering-Fehler oder Speicher nicht verfügbar | 503 | Kein Speicher; erneut versuchen nach 60 Sekunden |
| Ursprungsanfrage-Limit überschritten | 429 | Kein Speicher; Wiederholungsintervall in der Antwort |

Der Ursprung erlaubt dreißig Anfragen pro Minute pro Client-Adresse, einschließlich
ungültige Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich verifizierter Crawler. Es
erlaubt zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Das Überschreiten des Limits blockiert Anfragen für zehn Sekunden. Die allgemeine
Die Challenge-Regeln der öffentlichen Seite schließen diesen Pfad aus, sodass Bild-Crawler niemals
eine Browser-Challenge lösen.

von Cloudflare [Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
zwischenspeichert `.jpg` Antworten und Origin-Cache-Header berücksichtigt. Bewahren Sie den signierten Abfrage
Zeichenkette im Standard-Cache-Schlüssel. Wenden Sie keine überschreibende Cache-Dauer an, die
Fehlerantworten zwischenspeichert oder ignoriert `no-store`. Die deterministische Signatur vermeidet
einen Cache-Eintrag pro Seitenanfrage.

Stellen Sie die Infrastruktur-Ressource neben der Anwendung bereit. Vergewissern Sie sich, dass der Ursprung
nur über den vertrauenswürdigen Ingress erreichbar ist, da weitergeleitete Client-Adressen
vom bestehenden Request-Limiter vertraut sind. Der Browser-Pool und das Render-Budget
begrenzen zudem verteilte Misses und direkte Ursprungsanfragen.

## Lokale Konfiguration

Festlegen `GLOSSIA_OG_IMAGES=true` um den Browser-Pool in der Entwicklung zu aktivieren. Installieren
Google Chrome oder Chromium, um Assets mit zu erstellen `mix assets.build`, und konfigurieren Sie
die bestehenden object-storage-Umgebungsvariablen:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ausführen `mix ecto.setup` und `mix phx.server`. Wenn der Speicher konfiguriert ist, geben Seeds
das öffentliche `dev/glossia` Projekt ein Logo. Überprüfen Sie die `og:image` Metadaten eines
Dashboardseite, um die signierte Bildadresse zu erhalten.