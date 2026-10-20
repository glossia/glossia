%{
  title: "Ruhigere Übersetzungs-Pull-Requests",
  summary:
    "Was wir aus dem Einsatz von Glossia in einem aktiven Repository gelernt haben und wie sich Übersetzungs-Pull-Requests dadurch veränderten."
}
---

Man lernt am meisten das erste Mal, wenn das Werkzeug ein echtes Repository antrefft. Für uns war das Tuist. Ihr Team führt viele Merges auf `main` täglich durch, und Glossia tat genau das, wofür wir es gebaut hatten: es übersetzte jede Änderung und übertrug jede Datei so bald wie sie bereit war. Das Ergebnis war eine neue Pull-Request für fast jeden Merge, jede mit rund 150 Commits und einer CI-Warteschlange voller Prüfungen, die niemand angefordert hatte. Einige ihrer Dokumentationsseiten kehrten mit Komponenten und Warnungen zurück, die als reiner Text entflohen waren. Nicht die ruhige, Hintergrund-Erfahrung, über die wir ständig sprechen.

Das stach, weil wir immer sagten, das beste Übersetzungssystem ist eines, das man nicht überlegen muss. Eine Pull-Request, die Ihren CI überflutet oder Ihre Dokumentation verwüstet, ist das Gegenteil davon. Also gingen wir zurück und überdachten, wie Übersetzungen Ihr Repository erreichen.

Glossia hält nun pro Projekt nur eine einzige Pull-Request und vergrößert sie, wie Ihr Inhalt sich verändert. Es liest die Lockfiles, die bereits auf diesem Branch liegen, zus es übersetzt nur das Neue, und drückt es in Batches statt Datei für Datei über. Auf einem Repository wie Tuist's sind es nur ein paar Übertragungen, wobei es früher 150 gab.

Wir haben auch aufgehört, Teile Ihrer Dokumente zu berühren, die nicht unsere Sache sind. Glossia hat früher jede Seite neu aufgebaut, die es übersetzt hat, und alles, was es nicht vollständig verstehen konnte, wie ein Phoenix-Komponente oder eine GitHub-Warnung, konnte auf der anderen Seite entkommen. Jetzt tauscht es nur die Sätze aus, die es übersetzt hat, und hinterlässt alles andere genau so, wie Sie es geschrieben haben. Es gab einen netten Nebeneffekt, den wir nicht erwartet haben: weil das Modell nun ganze Sätze und den Rest der Seite sieht, lesen sich die Übersetzungen besser. Auf Japanisch muss ein Link nicht mehr unnatürlich dort sein, wo er im englischen Satz war.

Schließlich sagt Ihnen nun die Pull-Request, was passiert ist. Welche Sprachen und Dateien wurden übersetzt, aus welchen Commits, wie sie bewertet wurden, welche Glossar-Terme sie beeinflussten, und was, falls etwas, Ihre Aufmerksamkeit benötigt. Wir sehen es als Notiz, die ein sorgsamer Kollege Ihnen hinterlassen würde, bevor er eine Überprüfung anfordert.

Vielen Dank an das Tuist-Team für seine Geduld, während wir das geklärt haben. Wenn Glossia jemals so in Ihren Weg tritt, würden wir es gerne hören.
