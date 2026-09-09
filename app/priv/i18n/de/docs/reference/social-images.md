%{
  title: "Social Media-Bilder",
  summary: "Tägliche Dashboard-Vorschauen, Browser-Rendering, Speicher und Datenverkehrslimits.",
  category: "Referenz",
  order: 30
}
---
Die Dashboard-Seiten zeigen ein 1200 × 630 Bild über [Open Graph](https://ogp.me/)
und Twitter-Großbild-Metadaten. Öffentliche Projekte beinhalten ihren Namen, Abschnitt,
und hochgeladenes Logo. Öffentliche Konten erhalten eine abschnittsspezifische Vorschau. Privat
Konten und persönliche Einstellungen verwenden das generische Glossia-Branding.

## Bildidentität und Lebensdauer

Der Bild-Digest enthält den angezeigten Inhalt, die Projekt-Logorevision, die Vorlage,
Stile, Schriftarten, Markenasset, Abhängigkeits-Lockfile und aktueller Tag in
[Koordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Ändern eines dieser erstellt eine neue Adresse. Das Sortieren der Attribute und das Signieren
um Mitternacht hält die vollständige Adresse den Tag über stabil.

Die signierte Nutzlast kann von einem Besucher nicht geändert werden. Sie ist zwei Tage gültig,
aber nur die Nutzlast des aktuellen Tages kann ein fehlendes Bild erzeugen. Gesternes
gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu Objektsspeicher-Schlüsseln.

Erfolgreiche Bilder werden persistiert unter `og/images/<digest>.jpg` in der konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatible Bucket.
Nur eine explizite fehlende-Objekt-Antwort startet die Generierung. Speicherfehler
geben einen nicht zwischenspeicherbaren temporären Fehler zurück, ohne Chrome zu starten. Ein Upload muss
erfolgreich sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendern und Limits

Rendern verwendet Carta mit BrowseChrome, den gleichen Stack wie Tuists Bildrenderer.
Der überwachte Pool enthält zwei Browser. Jedes Rendering hat eine Frist von 15 Sekunden;
jede Anwendungsinstanz erlaubt höchstens zwölf neue Renderings pro Minute.
Anfragen für zwischengespeicherte Bilder verbrauchen dieses Kontingent nicht.

Cachex kombiniert gleichzeitige Anfragen für dasselbe Bild und behält bis zu 100
Bilder für fünf Minuten. Ein nichtblockierender PostgreSQL Advisory Lock verhindert
verschiedene Anwendungsrepliken, dasselbe Bild gleichzeitig zu rendern.
Andere Repliken erhalten einen vorübergehenden Fehler und können es erneut versuchen, sobald das Objekt existiert.

Die Vorlage kombiniert ein Noora-Sektion-Badge mit dem warmen Hintergrund von Glossia, Serif
Überschrift, Gradient-Akzent und unaufdringliche Fußzeile. Source Serif 4 und Inter sind
lokal gebündelt, sodass Vorschauen keinen Font-Service benötigen. Schriften und Raster
Logos sind eingebettet. Die Content-Security-Policy des Dokuments blockiert Skripte und
externe Ressourcen. Logos werden nur aus dem Avatarspeicher der Anwendung geladen
Präfix und sind auf fünf Millionen Bytes beschränkt, entsprechend den Projekt-Uploads.

## Antwortverhalten

| Ergebnis | Status | Cache-Verhalten |
|---|---|---|
| Gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, einen Tag, unveränderlich |
| Ungültige, abgelaufene oder veränderte Signatur | 404 | Kein Speicher |
| Gestriges Bild fehlt im Speicher | 404 | Kein Speicher |
| Browser belegt, Rendering-Fehler oder Speicherunverfügbarkeit | 503 | Kein Speicher; nach 60 Sekunden erneut versuchen |
| Origin-Anfrageerlaubnis überschritten | 429 | Kein Speicher; Warteintervall in der Antwort |

Das Origin erlaubt dreißig Anfragen pro Minute pro Client-Adresse, einschließlich
ungültige Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich validierter Crawler. Es
erlaubt zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Das Überschreiten des Limits blockiert Anfragen für zehn Sekunden. Der allgemeine
Die public-page Challenge-Regeln schließen diesen Pfad aus, sodass Bild-Crawler dies niemals ausführen müssen
eine Browser-Challenge lösen.

Cloudflares [Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
speichert `.jpg` Antworten und beachtet Ursprungs-Cache-Header. Halten Sie den signierten Query
String im Standard-Cache-Schlüssel. Wenden Sie keine überschreibende Cache-Dauer an, die
Fehlerantworten im Cache speichert oder ignoriert `no-store`. Die deterministische Signatur vermeidet
einen Cache-Eintrag pro Seitenanfrage.

Bereitstellen Sie die Infrastrukturressource neben der Anwendung. Stellen Sie sicher, dass der Origin
nur über den vertrauten Ingress erreichbar ist, da weitergeleitete Client-Adressen
vom vorhandenen Request-Limiter vertraut werden. Der Browser-Pool und das Render-Budget
bindet zudem verteilte Cache-Misses und direkte Origin-Anfragen.

## Lokale Konfiguration

Setzen `GLOSSIA_OG_IMAGES=true` um den Browser-Pool im Entwicklungsmodus zu aktivieren. Installieren Sie
Google Chrome oder Chromium, erstellen Sie Assets mit `mix assets.build`, und konfigurieren
die bestehenden object-storage-Umgebungsvariablen:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ausführen `mix ecto.setup` und `mix phx.server`. Mit konfiguriertem Speicher geben Seeds
das öffentliche `dev/glossia` Projekt ein Logo. Überprüfen Sie die `og:image` Metadaten eines
Dashboard-Seite, um die signierte Bildadresse zu erhalten.