%{
  title: "Social-Media-Bilder",
  summary: "Tägliche Dashboard-Vorschauen, Browser-Rendering, Storage- und Datenverkehrs-Limits.",
  category: "Referenz",
  order: 30
}
---
Dashboard-Seiten werben mit einem 1200 × 630 Bild durch [Open Graph](https://ogp.me/)
und Twitter-Metadaten für Großbilder. Öffentliche Projekte enthalten ihren Namen, Abschnitt,
und hochgeladenes Logo. Öffentliche Konten erhalten eine abschnittsspezifische Vorschau. Privat
Konten und persönliche Einstellungen nutzen generisches Glossia-Branding.

## Bildidentität und Lebensdauer

Der Bilddigest umfasst den angezeigten Inhalt, Projekt-Logo-Revision, Vorlage,
Stile, Schriftarten, Markenmaterial, Abhängigkeits-Lockfile und aktueller Tag in
[Koordinierte Weltzeit](https://www.timeanddate.com/time/aboututc.html).
Das Ändern eines dieser Werte erstellt eine neue Adresse. Das Sortieren der Attribute und Signieren
am Mitternacht hält die vollständige Adresse den ganzen Tag stabil.

Die gesignierten Nutzdaten können nicht von einem Besucher geändert werden. Sie sind zwei Tage gültig,
aber nur die Nutzdaten des aktuellen Tages können ein fehlendes Bild erzeugen. Gestern
gespeicherte Bilder bleiben lesbar. Abfrageparameter werden niemals zu Objekt-Speicher-Schlüsseln.

Erfolgreiche Bilder werden unter `og/images/<digest>.jpg` in der konfigurierten
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-kompatiblen Bucket.
Nur eine explizite fehlende-Objekt-Antwort startet die Generierung. Speicherausfälle
gibt einen nicht zwischenspeicherbaren vorübergehenden Fehler zurück, ohne Chrome zu starten. Ein Upload muss
erfolgreich abgeschlossen sein, bevor ein neu gerendertes Bild bereitgestellt wird.

## Rendering und Grenzwerte

Rendering verwendet Carta mit BrowseChrome, den gleichen Stack wie Tuist's Bild-Renderer.
Der überwachte Pool enthält zwei Browser. Jede Renderung hat eine 15-Sekunden-Frist;
Jede Anwendungsinstanz erlaubt maximal zwölf neue Renderungen pro Minute.
Anfragen für gespeicherte Bilder verbrauchen diese Quote nicht.

Cachex kombiniert gleichzeitige Anfragen für dasselbe Bild und behält bis zu 100
Bilder für fünf Minuten. Ein nicht blockierender PostgreSQL advisory lock verhindert
verschiedene Anwendungsreplikate, dasselbe Bild gleichzeitig zu rendern.
Andere Repliken erhalten einen vorübergehenden Fehler und können es erneut versuchen, sobald das Objekt existiert.

Das Template kombiniert ein Noora-Sektionsabzeichen mit dem warmen Hintergrund von Glossia, Serif
Überschrift, Farbverlauf-Akzent und zurückhaltende Fußzeile. Source Serif 4 und Inter sind
lokal gebündelt, sodass Vorschauen nicht von einem Schriftartendienst abhängen. Schriftarten und Raster
Logos werden eingebunden. Die Content-Security-Policy des Dokuments blockiert Skripte und
externe Ressourcen. Logos werden nur aus dem Avatar-Speicher der Anwendung geladen
Präfix und sind auf fünf Millionen Bytes begrenzt, was den Projekt-Uploads entspricht.

## Antwortverhalten

| Ergebnis | Status | Cache-Verhalten |
|---|---|---|
| Gespeichertes oder neu persistiertes Bild | 200 | Öffentlich, ein Tag, unveränderlich |
| Ungültige, abgelaufene oder manipulierte Signatur | 404 | Kein Speicher |
| Bild von gestern fehlt im Speicher | 404 | Kein Speicher |
| Browser belegt, Darstellungsfehler oder Speicher nicht verfügbar | 503 | Kein Speicher; Wiederholen nach 60 Sekunden |
| Ursprungsanfragebegrenzung überschritten | 429 | Kein Speicher; Wiederholungsintervall in der Antwort |

Der Ursprung erlaubt dreißig Anfragen pro Minute pro Client-Adresse, einschließlich
ungültige Anfragen.

## Cloudflare

Die `social-images-rate-limit.yaml` Ressource im Infrastruktur-Repository
entspricht `GET` und `HEAD` Anfragen unter `/og/`, einschließlich validierter Crawler. Es
ermöglicht zwanzig Anfragen pro zehn Sekunden pro Client-Adresse und Cloudflare
Standort. Überschreiten des Limits blockiert Anfragen für zehn Sekunden. Der allgemeine
Die Public-Page-Challenge-Regeln schließen diesen Pfad aus, sodass Bildkrawler nicht
eine Browser-Herausforderung lösen müssen.

von Cloudflare [das Standard-Cache-Verhalten](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
speichert `.jpg` Antworten und berücksichtigt Origin-Cache-Header. Halten Sie die signierte
String im Standard-Cache-Schlüssel. Wenden Sie keine überschreibende Cache-Dauer an, die
fehlerhafte Antworten im Cache speichert oder ignoriert `no-store`. Die deterministische Signatur vermeidet
ein Cache-Eintrag pro Seitenanfrage.

Bereitstellen Sie die Infrastrukturressource parallel zur Anwendung. Stellen Sie sicher, dass der Ursprung
nur über den vertrauenswürdigen Ingress erreichbar ist, da weitergeleitete Client-Adressen
von dem bestehenden Anforderungsbegrenzer vertraut werden. Der Browser-Pool und der Render-Haushalt
sowie verteilte daneengeben und Direkt-Ursprung-Anfragen steuern.

## Lokale Konfiguration

Set `GLOSSIA_OG_IMAGES=true` um den Browser-Pool in der Entwicklung zu aktivieren. Installieren Sie
Google Chrome oder Chromium, und erstellen Sie Ressourcen mit `mix assets.build`, und konfigurieren
die bestehenden object-storage-Umgebungsvariablen:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ausführen `mix ecto.setup` und `mix phx.server`. Mit konfiguriertem Speicher, Startwerte geben
das öffentliche `dev/glossia` Projekt ein Logo. Überprüfen Sie das `og:image` Metadaten auf einem
Dashboard-Seite zum Abruf der signierten Bildadresse.