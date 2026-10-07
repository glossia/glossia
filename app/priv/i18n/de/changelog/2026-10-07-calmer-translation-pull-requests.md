%{
  title: "Ruhigere Übersetzungs-Pull Requests",
  summary:
    "Was wir aus dem Loslassen von Glossia auf einem sehr aktiven Repository gelernt haben und wie sich Übersetzungs-Pull Requests deswegen verändert haben."
}
---
Du lernst viel, das erste Mal, wenn dein Tool auf ein echtes Repository trifft. Für uns war das Tuist. Ihr Team merge mit `main` viele Male täglich, und Glossia hat genau das getan, wofür es gebaut wurde: Es übersetzte jede Änderung und schob jede Datei, sobald sie bereit war. Das Ergebnis war für fast jeden Merge eine neue Pull Request, jede mit rund 150 Commits, und einer CI-Warteschlange voller Checks, die niemand angefordert hatte. Einige ihrer Dokumentationsseiten kamen auch mit Komponenten und Alerts zurück, die als reiner Text freigegeben waren. Nicht die stille Hintergrund-Erfahrung, über die wir immer wieder sprechen.

Das hat uns wehgetan, weil wir immer gesagt haben, das beste Übersetzungssystem ist eines, an dem man nicht nachdenken muss. Eine Pull Request, die die CI überschwebt oder deine Dokus zerkaut, ist das Gegenteil davon. Also sind wir zurückgegangen und haben neu gedacht, wie Übersetzungen zu deinem Repository gelangen.

Glossia hält nun pro Projekt nur eine einzige Pull Request und lässt sie wachsen, wenn sich dein Inhalt ändert. Es liest die Lock-Dateien, die bereits auf diesem Branch liegen, sodass es nur Übersetzt, was neu ist, und schiebt in Batches statt Datei um Datei. Auf einem Repository wie dem von Tuist, das sind ein paar Pushes, wo zuvor hundertfünfzig waren.

Wir haben auch aufgehört, Teile deiner Dokumente anzurühren, die nicht unsere Aufgabe sind. Glossia hat früher jede Seite neu erstellt, die es übersetzt hat, und alles, was es nicht vollständig verstand, wie eine Phoenix-Komponente oder ein GitHub-Alarm, konnte auf der anderen Seite unformatiert erscheinen. Jetzt tauscht es nur die Sätze aus, die es übersetzt hat, und hinterlässt alles andere genau so, wie du es geschrieben hast. Es gab einen angenehmen Nebeneffekt, den wir nicht erwartet haben: weil das Modell nun ganze Sätze und den Rest der Seite sieht, lesen sich die Übersetzungen besser. Im Japanischen muss ein Link nicht mehr schief sitzen, wo er im englischen Satz war.

Schließlich sagt dir nun die Pull Request, was passiert ist. Welche Sprachen und Dateien wurden übersetzt, aus welchen Commits, wie sie bewertet wurden, welche Glossar-Terme sie geprägt haben, und was, falls etwas, deine Aufmerksamkeit erfordert. Wir sehen es als die Notiz an, die ein sorgsamer Kollege dir vor der Überprüfung hinterlassen würde.

Danke an das Tuist-Team für seine Geduld, während wir dies verstanden haben. Wenn Glossia sich jemals so in deinen Weg stellt, würden wir gerne davon erfahren.