%{
  title: "Ruhigere Übersetzungs-Pull-Requests",
  summary:
    "Was wir aus dem Loslassen von Glossia auf einem aktiven Repository gelernt haben, und wie Übersetzungs-Pull-Requests sich dadurch verändert haben."
}
---

Man lernt am meisten beim ersten Mal, wenn Ihr Werkzeug auf ein echtes Repository trifft. Für uns war das Tuist. Ihr Team merge in `main` sehr häufig pro Tag, und Glossia erledigte genau das, wofür wir es gebaut haben: es übersetzte jede Änderung und schob jede Datei sofort, sobald sie bereit war. Das Ergebnis war ein neuer Pull-Request für fast jeden Merge, jeweils mit rund 150 Commits, und eine CI-Warteschlange voller Checks, die von niemandem angefordert wurden. Einige ihrer Dokumentationsseiten kamen auch mit Komponenten und Warnungen zurück, die in reinen Text entkommen waren. Das ist nicht die leise, im Hintergrund ablaufende Erfahrung, von der wir immer sprechen.

Das hat gekränkt, weil wir stets betont haben, dass das beste Übersetzungssystem eines ist, über das man nicht nachdenken muss. Ein Pull-Request, der Ihre CI überflutet oder Ihre Dokumentation zerstört, ist genau das Gegenteil davon.

Glossia führt nun pro Projekt nur einen einzelnen Pull-Request und erweitert diesen, wenn sich Ihr Inhalt ändert. Es liest die Lockdateien, die bereits auf diesem Branch liegen, übersetzt also nur das Neue und drückt in Chargen statt Datei für Datei. Bei einem Repository wie dem von Tuist ist das nur ein paar Versenden, wo früher Hundertfünfzig waren.

Wir haben auch aufgehört, Teile Ihrer Dokumente anzurühren, die nicht zu uns gehören. Glossia baute früher jede einzelne Übersetzungsseite neu auf, und alles, was es nicht vollständig verstand, wie eine Phoenix-Komponente oder ein GitHub-Alert, konnte am Ende unverschlüsselt herauskommen. Jetzt ersetzt es nur die Sätze, die es übersetzt hat, und lässt alles andere exakt so, wie Sie es geschrieben haben. Es gab einen positiven Nebeneffekt, den wir nicht erwarteten: weil das Modell nun ganze Sätze und den Rest der Seite sieht, lesen die Übersetzungen besser. Im Japanischen muss ein Link nicht mehr sperrig dorthin sitzen, wo er im englischen Satz stand.

Schließlich meldet Ihnen der Pull-Request nun, was passiert ist. Welche Sprachen und Dateien übersetzt wurden, aus welchen Commits, wie sie bewertet wurden, welche Glossar-Begriffe sie geprägt haben, und was, wenn überhaupt, Ihre Aufmerksamkeit erfordert. Wir betrachten das als die Notiz, die ein sorgsamer Kollege Ihnen hinterlassen würde, bevor er nach einer Überprüfung fragt.

Vielen Dank an das Tuist-Team für Ihre Geduld, während wir dies analysiert haben. Wenn Glossia jemals auf diese Weise in Ihrem Weg steht, würden wir es gerne hören.
