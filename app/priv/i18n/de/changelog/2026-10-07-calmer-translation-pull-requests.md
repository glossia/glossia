%{
  title: "Sanftere Übersetzungs-Pull-Requests",
  summary:
    "Was wir aus dem Einsatz von Glossia in einem sehr aktiven Repository gelernt haben und wie sich Übersetzungs-Pull-Requests dadurch veränderten."
}
---

Man lernt viel beim ersten Mal, wenn Ihr Tool auf ein echtes Repository trifft. Für uns war das Tuist. Ihr Team merge in `main` viele Male am Tag, und Glossia tat genau das, wofür wir es gebaut haben: Es übersetzte jede Änderung und schob jede Datei ab, sobald sie bereit war. Das Ergebnis war für fast jeden Merge ein neuer Pull Request, jeder mit rund 150 Commits, und eine CI-Warteschlange voller Prüfungen, die niemand angefordert hatte. Auch einige ihrer Dokumentationsseiten kehrten mit in reinen Text entkommenden Komponenten und Alerts zurück. Nicht die stille, im Hintergrund stattfindende Erfahrung, die wir immer noch besprechen.

Das stach, denn wir haben immer gesagt, dass das beste Übersetzungssystem eines ist, über das man nicht nachdenken muss. Ein Pull Request, der Ihre CI überflutet oder Ihre Dokumente zerbricht, ist das genaue Gegenteil davon. Also sind wir zurückgegangen und haben nachgedacht, wie Übersetzungen in Ihr Repository gelangt werden.

Glossia hält nun einen Pull Request pro Projekt und lässt ihn wachsen, je nach Ihren Inhaltsänderungen. Es liest die Lockdateien, die bereits auf diesem Branch stehen, übersetzt also nur das Neue und schiebt in Chunks statt Datei um Datei. In einem Repository wie Tuist sind das nur ein paar Pushes, wo früher einhundertfünfzig waren.

Wir haben auch aufgehört, Teile Ihrer Dokumente zu berühren, die nicht zu unseren gehören. Glossia hat früher jede Seite neu aufgebaut, die es übersetzt, und womöglich alles, was es nicht vollständig verstand, wie eine Phoenix-Komponente oder eine GitHub-Warnung, die auf der anderen Seite zurückkam, heil. Jetzt tauscht es nur die Sätze aus, die es übersetzt, und lässt alles andere genau so, wie Sie es geschrieben haben. Es gab einen schönen Nebeneffekt, den wir nicht erwartet haben: Weil das Modell nun ganze Sätze und den Rest der Seite sieht, lesen sich die Übersetzungen besser. Auf Japanisch muss ein Link nicht mehr unbequem dastehen, wo er im Englischen Satz stand.

Schließlich erzählt der Pull Request nun, was passiert ist. Welche Sprachen und Dateien übersetzt wurden, aus welchen Commits, wie sie bewertet wurden, welche Glossarbegriffe sie prägten und was, falls vorhanden, Ihre Aufmerksamkeit benötigt.

Danke an das Tuist-Team für ihre Geduld, während wir das geklärt haben. Wenn Glossia jemals so in Ihren Weg kommt, würden wir uns freuen, davon zu hören.
