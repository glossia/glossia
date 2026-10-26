%{
  title: "Socialbilder",
  summary: "Dashboard-Link-Vorschauen, Projekt-Branding, Bilderupdates und Verfügbarkeit.",
  category: "Referenz",
  section: "analytics",
  order: 30
}
---

Glossia erstellt soziale Bilder für Dashboard-Links auf seinem gehosteten Dienst.

## Linkvorschau

Dashboard-Seiten werben mit einem 1200 × 630 großen Bild über [offene Graphen](https://ogp.me/) und Twitter-Metadaten für große Bilder. Das Teilen eines Links in einem Dienst, der diese Metadaten liest, kann die Vorschau anzeigen. Der teilsende Dienst entscheidet, wann er diese abgerufen oder aktualisiert wird.

Öffentliche Projekte enthalten ihren Namen, den Abschnitt und das hochgeladene Logo. Öffentliche Konten erhalten eine abschnittsspezifische Vorschau. Private Konten und persönliche Einstellungen verwenden generisches Glossia-Branding.

## Projektbranding

Laden Sie das Projektlogo in Glossia hoch oder ersetzen Sie es, um das für die öffentliche Vorschau verwendete Branding zu ändern. Logos sind auf fünf Millionen Bytes beschränkt, passend zu den Projekthochladungen.

Private Projektdaten sind nicht in einer öffentlichen Vorschau für soziale Bilder enthalten. Eine Vorschau gewährt keinen Zugriff auf die verlinkte Dashboard-Seite.

## Bilderaktualisierungen

Bildadressen ändern sich, wenn der angezeigte Inhalt, das Projektlogo, die tägliche Bildversion oder die Glossia-Rendering-Implementierung geändert wird. Ein erfolgreiches Bild kann für einen Tag zwischengespeichert werden. Teildienste können ihre eigene zwischengespeicherte Vorschau beibehalten, daher garantiert der Austausch eines Logos keine sofortige Aktualisierung überall.

Glossia verwaltet Bildgenerierung, Speicherung, Schriftarten und Caching.

## Verfügbarkeit

| Ergebnis | Antwort |
|---|---|
| Bild verfügbar | 200 |
| Ungültige oder abgelaufene Bildadresse | 404 |
| Bild vorübergehend nicht verfügbar | 503, mit einer Wiederholungsverzögerung von 60 Sekunden |
| Anfragegrenze überschritten | 429, mit einer Wiederholungsverzögerung in der Antwort |

Wenn eine Vorschau fehlt, öffnen Sie die Dashboard-Seite und teilen Sie den aktuellen Link. Bei einem vorübergehenden Fehler wiederholen Sie den Versuch nach der angegebenen Verzögerung. Wenn das Problem weiterhin besteht, wenden Sie sich an den Glossia-Support.
