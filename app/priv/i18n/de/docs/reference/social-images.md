%{
  title: "Social-Media-Bilder",
  summary: "Dashboard-Link-Vorschauen, Projektbranding, Bildupdates und Verfügbarkeit.",
  category: "Referenz",
  section: "analytics",
  order: 30
}
---

Glossia generiert Social-Media-Bilder für Dashboard-Links auf seinem gehosteten Dienst.

## Link-Vorschau

Dashboard-Seiten melden ein Bild von 1200 × 630 über [Open Graph](https://ogp.me/) und Twitter-Daten für große Bilder an. Das Teilen eines Links in einem Dienst, der diese Metadaten liest, kann die Vorschau anzeigen. Der Teiledienst entscheidet, wann er diese abruft oder aktualisiert.

Öffentliche Projekte enthalten ihren Namen, ihre Sektion und das hochgeladene Logo. Öffentliche Konten erhalten eine sektorenbezogene Vorschau. Private Konten und persönliche Einstellungen verwenden die generische Glossia-Branding.

## Projekt-Branding

Laden Sie das Projektlogo in Glossia hoch oder ersetzen Sie es, um das Branding in der öffentlichen Vorschau zu ändern. Logos sind auf fünf Millionen Bytes beschränkt, entsprechend Projekt-Uploads.

Informationen zu privaten Projekten sind nicht in einer öffentlichen Social-Media-Vorschau enthalten. Eine Vorschau gewährt keinen Zugriff auf die verknüpfte Dashboard-Seite.

## Bild-Updates

Bild-Adressen ändern sich, wenn der angezeigte Inhalt, das Projektlogo, die tägliche Bildversion oder die Glossia-Rendering-Implementierung geändert wird. Ein erfolgreiches Bild kann einen Tag lang zwischengespeichert werden. Teildienste können ihre eigene zwischengespeicherte Vorschau behalten, sodass das Ersetzen eines Logos keine sofortige Aktualisierung überall garantiert.

Glossia verwaltet Bildgenerierung, Speicherung, Schriftarten und Caching.

## Verfügbarkeit

| Ergebnis | Antwort |
|---|---|
| Bild verfügbar | 200 |
| Ungültige oder abgelaufene Bild-Adresse | 404 |
| Bild vorübergehend nicht verfügbar | 503, mit einer Wiederholungsverzögerung von 60 Sekunden |
| Anforderungslimit überschritten | 429, mit einer Wiederholungsverzögerung in der Antwort |

Wenn eine Vorschau fehlt, rufen Sie die Dashboard-Seite auf und teilen Sie den aktuellen Link. Bei einem vorübergehenden Fehler erneut nach der angegebenen Verzögerung versuchen. Wenn das Problem besteht, kontaktieren Sie den Glossia-Support.
