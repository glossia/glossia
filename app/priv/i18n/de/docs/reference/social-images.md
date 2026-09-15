%{
  title: "Social-Media-Bilder",
  summary: "Tägliche Dashboard-Vorschauen, Browserdarstellung, Speicher- und Verkehrslimits.",
  category: "Referenz",
  order: 30
}
---
Dashboardseiten werben mit einem 1200 × 630-Bild über [Open Graph](https://ogp.me/)
und Twitter-Metadaten für große Bilder. Öffentliche Projekte beinhalten ihren Namen, Abschnitt,
und hochgeladenes Logo. Öffentliche Konten erhalten eine bereichsspezifische Vorschau. Privat
Konten und persönliche Einstellungen verwenden das generische Glossia-Branding.

## Bildidentität und Lebensdauer

Der Bild-Digest enthält den angezeigten Inhalt, die Projektlogo-Revision, die Vorlage,
Stile, Schriftarten, Markenasset, Abhängigkeits-Lockfile und den aktuellen Tag in
[Koordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Das Ändern eines dieser Werte erstellt eine neue Adresse. Das Sortieren der Attribute und das Signieren
um Mitternacht bleibt die vollständige Adresse den ganzen Tag stabil.

Die signierte Nutzlast kann von einem Besucher nicht geändert werden. Sie ist zwei Tage gültig,
aber nur die Nutzlast des aktuellen Tages darf ein fehlendes Bild generieren. Gestern
gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu object-store-Schlüsseln.

Erfolgreiche Bilder werden unter `og/images/<digest>.jpg` in der konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatiblen Bucket.
Nur eine explizite missing-object-Antwort startet die Generierung. Speicherfehler
gibt einen nicht zwischenspeicherbaren vorübergehenden Fehler zurück, ohne Chrome zu starten. Ein Upload muss
erfolgreich sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendern und Limits

Das Rendern nutzt Carta mit BrowseChrome, denselben Stack wie Tuists Bildrenderer.
Der überwachte Pool enthält zwei Browser. Jeder Render hat eine 15-Sekunden-Frist;
jede Anwendungsinstanz erlaubt höchstens zwölf neue Rends pro Minute.
Anfragen für gespeicherte Bilder verbrauchen dieses Kontingent nicht.

Cachex bündelt parallele Anfragen für dasselbe Bild und behält bis zu 100
Bilder für fünf Minuten. Ein nichtblockierender PostgreSQL advisory lock verhindert
verschiedene Anwendungsreplikate daran, gleichzeitig dasselbe Bild zu rendern.
Weitere Replikate erhalten einen vorübergehenden Fehler und können es erneut versuchen, sobald das Objekt existiert.

Die Vorlage kombiniert ein Noora-Sektion-Badge mit dem warmen Hintergrund von Glossia, Serif
Überschrift, Verlauf-Akzent und dezenter Fußbereich. Source Serif 4 und Inter sind
lokal gebündelt, sodass Vorschauen nicht von einem Font-Service abhängig sind. Schriften und Raster
Logos werden eingebettet. Die Content-Security-Richtlinie des Dokuments blockiert Skripte und
externen Ressourcen. Logos werden nur aus dem Avatar-Speicher der Anwendung geladen
Präfix und sind auf fünf Millionen Bytes beschränkt, entsprechend den Projekt-Uploads.

## Antwortverhalten

| Ergebnis | Status | Cacheverhalten |
|---|---|---|
| Gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, einen Tag, unveränderlich |
| Ungültige, abgelaufene oder veränderte Signatur | 404 | Kein Speicher |
| Bild von gestern fehlt im Speicher | 404 | Kein Speicher |
| Browser beschäftigt, Render-Fehler oder Speicher nicht verfügbar | 503 | Kein Speicher; erneut versuchen nach 60 Sekunden |
| Ursprungsanfrage-Limit überschritten | 429 | Kein Speicher; Wiederholungsintervall in der Antwort |

Der Ursprung erlaubt dreißig Anfragen pro Minute pro Client-Adresse, einschließlich
ungültiger Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich verifizierter Crawler. Es
ermöglicht zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Das Überschreiten des Limits blockiert Anfragen für zehn Sekunden. Das allgemeine
Die Public-Page-Challenge-Regeln schließen diesen Pfad aus, sodass Bild-Crawler dies niemals tun müssen, um
eine Browser-Challenge zu lösen.

von Cloudflare [Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
speichert `.jpg` Antworten und Origin-Cache-Header beachten. Halten Sie die signierte Abfrage
Zeichenfolge im Standard-Cache-Schlüssel. Wenden Sie keine überschreibende Cache-Dauer an, die
Fehlerantworten im Cache speichert oder ignoriert `no-store`. Die deterministische Signatur vermeidet
einen Cache-Eintrag pro Seitenanfrage.

Bereitstellen Sie die Infrastrukturressource parallel zur Anwendung. Stellen Sie sicher, dass der Origin
ist ausschließlich über den vertrauenswürdigen Ingress erreichbar, da zugeleitete Client-Adressen
durch den bestehenden Request-Limiter vertraut werden. Der Browser-Pool und das Render-Budget
begrenzen zudem verteilte Cache-Misses und Direkt-Origin-Anfragen.

## Lokale Konfiguration

Festlegen `GLOSSIA_OG_IMAGES=true` um den Browser-Pool in der Entwicklung zu aktivieren. Installieren
Google Chrome oder Chromium, um Assets mit erstellen `mix assets.build`, und konfigurieren
die bestehenden Objektspeicher-Umgebungsvariablen:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ausführen `mix ecto.setup` und `mix phx.server`. Sobald der Speicher konfiguriert ist, verleihen Seeds
das öffentliche `dev/glossia` Projekt ein Logo. Betrachten Sie die `og:image` Metadaten auf einem
Dashboardseite, um die Adresse des signierten Bildes zu erhalten.