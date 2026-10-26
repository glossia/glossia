%{
  title: "Ruhigere Übersetzungs-Pull-Requests",
  summary:
    "Was wir aus dem Einsatz von Glossia auf einem aktiv genutzten Repository gelernt haben, und wie Übersetzungs-Pull-Requests sich dadurch veränderten."
}
---

Du lernst viel das erste Mal, wenn dein Tool auf ein echtes Repository trifft. Für uns war das Tuist. Ihr Team merge viele Mal am Tag zu `main` und Glossia tat genau das, wofür wir es gebaut hatten: es übersetzte jede Änderung und schob jede Datei sofort, sobald sie bereit war. Das Ergebnis war ein neuer Pull Request für fast jeden Merge, jeder mit etwa 150 Commits, und eine CI-Warteschlange voller Checks, die niemand angefordert hatte. Einige ihrer Dokumentationsseiten kamen mit Komponenten und Warnmeldungen zurück, die als Klartext ausfielen. Nicht die leise, Hintergrund-Erfahrung, von der wir ständig sprechen.

Das stach, weil wir schon immer sagten, das beste Übersetzungssystem ist eines, über das man nicht nachdenken muss. Ein Pull Request, der deine CI überflutet oder deine Docs zerstört, ist das Gegenteil davon. Deshalb sind wir zurückgegangen und haben neu darüber nachgedacht, wie Übersetzungen zu deinem Repository gelangen.

Glossia hält nun pro Projekt nur einen einzigen Pull Request und erweitert diesen, wenn sich dein Inhalt ändert. Es liest die Lock-Dateien, die bereits auf diesem Branch liegen, sodass es nur das Übersetzt, was Neu ist, und schiebt es in Batches statt Datei für Datei. Bei einem Repository wie Tuist ist das ein paar Schüben, wo früher hundertfünfzig waren.

Wir haben auch aufgehört, Teile deiner Dokumente an der Hand zu haben, die nicht unsere Verantwortung sind. Glossia baute früher jede Seite neu auf, die es übersetzte, und alles, was es nicht vollständig verstand, wie eine Phoenix-Komponente oder eine GitHub-Warnung, konnte auf der anderen Seite in Klartext kommen. Nun tauscht es nur die von ihm übersetzten Sätze aus und hinterlässt alles andere exakt so, wie du es geschrieben hast. Es gab einen schönen Nebeneffekt, den wir nicht erwartet hatten: weil das Modell nun ganze Sätze und den Rest der Seite sieht, lesen die Übersetzungen besser. Im Japanischen muss ein Link nicht mehr unangenehm dort sitzen, wo er im Satz war.

Schließlich sagt dir jetzt der Pull Request, was passiert ist. Welche Sprachen und Dateien übersetzt wurden, aus welchen Commits, wie sie bewertet wurden, welche Glossar-Begriffe sie prägen, und was, falls etwas, deine Aufmerksamkeit benötigt. Wir denken es als die Notiz, die ein sorgsamer Kollege dir hinterlassen würde, bevor er eine Überprüfung anfordert.

Danke an das Tuist-Team für ihre Geduld, während wir das herausfanden. Wenn Glossia jemals auf deinem Weg wie dies im Weg steht, würden wir gerne darüber hören.
