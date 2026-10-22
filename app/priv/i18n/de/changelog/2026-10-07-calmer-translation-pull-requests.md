%{
  title: "Ruhigere Übersetzungs-Pull-Requests",
  summary:
    "Was wir aus dem Einsatz von Glossia in einem aktiven Repository gelernt haben und wie sich Übersetzungs-Pull-Requests dadurch veränderten."
}
---

Das lernst du am ersten Mal, wenn dein Tool auf ein echtes Repository trifft. Für uns war das Tuist. Ihr Team führt in `main` mehrmals täglich einen Merge durch, und Glossia tat genau das, wofür wir es gebaut haben: Es übersetzte jede Änderung und pushte jedes File, sobald es bereit war. Das Ergebnis war für fast jeden Merge eine neue Pull Request, jede mit etwa 150 Commits, und eine CI-Warteschlange voller Checks, von denen niemand angefordert hatte. Auch einige ihrer Dokumentationsseiten kamen zurück mit Komponenten und Alerts, die in reines Textformat entkamen. Nicht das stille, im Hintergrund ablaufende Erlebnis, von dem wir ständig sprechen.

Das tat weh, denn wir haben immer gesagt, das beste Übersetzungssystem ist eines, an dem man nicht nachdenken muss. Eine Pull Request, die deinen CI überflutet oder deine Docs anrümpelt, ist genau das Gegenteil davon. Deshalb sind wir zurückgegangen und haben neu überdacht, wie Übersetzungen dein Repository erreichen.

Glossia pflegt nun pro Projekt eine einzelne Pull Request und lässt sie wachsen, wenn sich dein Inhalt ändert. Es liest die Lockdateien, die auf diesem Branch bereits liegen, übersetzt daraus nur das Neue und schiebt in Batches statt Datei für Datei. Auf einem Repository wie Tuist sind das ein paar Pushes, wo zuvor 150 waren.

Wir haben auch aufgehört, Teile deiner Dokumente zu bearbeiten, die nicht unsere Verwaltung betreffen. Glossia hat früher jede übersetzte Seite neu aufgebaut, und alles, was es nicht vollständig verstand, wie eine Phoenix-Komponente oder eine GitHub-Alert, konnte auf der anderen Seite als reines Text entkommen. Jetzt tauscht es nur die Sätze aus, die es übersetzt hat, und lässt alles andere exakt so, wie du es geschrieben hast. Ein netter Nebeneffekt, den wir nicht erwartet haben: Weil das Modell nun ganze Sätze und den Rest der Seite sieht, lesen die Übersetzungen besser. Im Japanischen muss ein Link nicht mehr unangenehm sitzen, wo er im englischen Satz war.

Abschließend sagt dir die Pull Request nun, was passiert ist. Welche Sprachen und Dateien wurden übersetzt, aus welchen Commits, wie sie bewertet wurden, welche Glossar-Terme sie geprägt haben und was, falls Einführung, deine Aufmerksamkeit erfordert. Wir betrachten es als die Notiz, die ein sorgsamer Kollege dir hinterlassen würde, bevor er nach einer Überprüfung fragt.

Vielen Dank an das Tuist-Team für die Geduld, während wir das geklärt haben. Sollte Glossia jemals so in deinen Weg kommen, würden wir es gerne hören.
