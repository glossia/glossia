%{
  title: "Social Media-Bilder",
  summary: "Dashboard-Link-Vorschauen, Projekt-Branding, Bild-Updates und Verfügbarkeit.",
  category: "Referenz",
  section: "analytics",
  order: 30
}
---
Glossia erstellt Social-Media-Bilder für Dashboard-Links auf seinem gehosteten Dienst.

## Linkvorschauen

Dashboard-Seiten zeigen ein 1200 × 630 Bild über [Open Graph](https://ogp.me/) und Metadaten für große Twitter-Bilder. Das Teilen eines Links in einem Dienst, der diese Metadaten liest, kann die Vorschau anzeigen. Der Dienst entscheidet, wann er sie abruft oder aktualisiert.

Öffentliche Projekte enthalten ihren Namen, ihren Abschnitt und das hochgeladene Logo. Öffentliche Konten erhalten eine abschnittsspezifische Vorschau. Private Konten und persönliche Einstellungen verwenden die generische Glossia-Branding.

## Projekt-Branding

Laden Sie das Projekt-Logo hoch oder ersetzen Sie es in Glossia, um das Branding der öffentlichen Vorschau zu ändern. Logos sind auf fünf Millionen Bytes begrenzt, entsprechend den Projekthochladungen.

Private Projektinformationen sind nicht in einer öffentlichen Social-Image-Vorschau enthalten. Eine Vorschau gewährt keinen Zugriff auf die verknüpfte Dashboardseite.

## Bildaktualisierungen

Bildadressen ändern sich, wenn der angezeigte Inhalt, das Projektlogo, die tägliche Bildversion oder die Glossia-Rendering-Implementierung geändert wird. Ein erfolgreiches Bild kann einen Tag lang zwischengespeichert werden. Sharing-Dienste können ihre eigene zwischengespeicherte Vorschau beibehalten, sodass das Ersetzen eines Logos kein sofortiges Update überall garantiert.

Glossia verwaltet die Bildgenerierung, -speicherung, Schriftarten und Caching.

## Verfügbarkeit

| Ergebnis | Antwort |
|---|---|
| Bild verfügbar | 200 |
| Ungültige oder abgelaufene Bildadresse | 404 |
| Bild vorübergehend nicht verfügbar | 503, mit einer Wiederholungsverzögerung von 60 Sekunden |
| Anforderungslimit überschritten | 429, mit einer Wiederholungsverzögerung in der Antwort |

Wenn eine Vorschau fehlt, öffnen Sie die Dashboardseite und teilen Sie dessen aktuellen Link. Bei einem vorübergehenden Fehler, versuchen Sie es nach der angegebenen Verzögerung erneut. Wenn das Problem weiterhin besteht, wenden Sie sich an den Glossia-Support.