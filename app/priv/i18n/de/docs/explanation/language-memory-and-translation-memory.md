%{
  title: "Sprachspeicher und Übersetzungsspeicher",
  summary:
    "Wie Stimme und Terminologie überprüfte Übersetzungen ergänzen, ohne die Lieferung an ein proprietäres Speichermodell zu binden.",
  category: "Erklärung",
  section: "translation",
  order: 4
}
---

Ein Übersetzungsspeicher erfasst üblicherweise zuvor bereits übersetzte Quell-Ziel-Segmente. Ein passendes oder ähnliches Quellsegment kann frühere Arbeit wiederverwenden. Dies ist von Wert für wiederkehrende Materialien und zur Pflege geprüfter Übersetzungen.

Der Sprachspeicher von Glossia befriedigt einen weiteren Bedarf: die Prinzipien, die neuem Schreiben den Beigeschmack der Organisation verleihen, selbst wenn der Satz noch nie zuvor aufgetaucht ist.

## Erinnern an Ergebnisse versus Erinnern an Intentionen

Eine geprüfte Übersetzung antwortet, „Wie haben wir das zuvor übersetzt?”. Stimmenthaltung und ein Glossar beantworten Fragen wie:

- Welche Produktsbegriffe sollen unverändert bleiben?
- Welche Terminologie verwenden wir konsequent?
- Welcher Ton passt zu diesem Publikum?
- Welche Sprachentscheidungen sollte ein Agent respektieren, wenn er neues Material entwickelt?

Diese Eingaben können bei der Lokalisierung sowie bei der Inhaltserstellung in der Quellsprache helfen. Sie beschränken sich nicht nur darauf, ein entsprechendes Zielsegment abzurufen.

## Komplementäre Werkzeuge

Übersetzungsspeicher und Sprachrichtlinien lösen überlappende, aber unterschiedliche Probleme. Glossia verspricht nicht, dass modellgenerierter Text jedes geprüfte Segment ersetzen kann, sowie dass die Eingabeaufforderung linguistische Korrektheit garantiert.

Die wichtigste architektonische Entscheidung besteht nicht darin, einen proprietären Speicher als einzige Autorität für den Kirchlichkeit des Unternehmens zu machen. Repository-eigenen Inhalt, wiederverwendbaren Kontext, Versionshistorie und Prüfung tragen alle zu einem Prozess bei, den das Team verstehen und pflegen kann.

## Kontext benötigt nach wie vor Überprüfung

Anleitung kann unvollständig oder widersprüchlich sein. Ein Begriff kann in verschiedenen Produkten unterschiedliche Bedeutungen haben. Menschen bleiben für die Entscheidung verantwortlich, ob das Ergebnis genau und angemessen ist; Validierung kann strukturelle Fehler erkennen, kann aber nicht beweisen, dass jeder Satz korrekt ist.

Lesen Sie [Warum Glossia](./why-glossia) für das übergeordnete Modell und [Kontinuierliche Lokalisierung](./continuous-localization) für die Beziehung zur Lieferung.
