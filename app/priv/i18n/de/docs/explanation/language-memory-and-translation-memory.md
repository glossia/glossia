%{
  title: "Sprachenspeicher und Übersetzungsspeicher",
  summary:
    "Wie Stimme und Terminologie geprüfte Übersetzungen ergänzen, ohne die Lieferung an einen proprietären Speicher zu binden.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 4
}
---

Ein Übersetzungsspeicher erfasst normalerweise zuvor übersetzte Quellzielabschnitte. Ein passender oder ähnlicher Quellabschnitt kann frühere Arbeit wiederverwenden. Dies ist wertvoll für wiederkehrendes Material und zum Bewahren geprüfter Übersetzungen.

Das Sprachgedächtnis von Glossia begegnet einem anderen Bedarf: den Prinzipien, die neuem Texten den Klang der Organisation verleihen, selbst wenn der Satz noch nie zuvor aufgetaucht ist.

## Ausgabe im Gedächtnis versus Intention im Gedächtnis

Eine geprüfte Übersetzung antwortet: „Wie haben wir das zuvor übersetzt?' Sprachführung und ein Glossar beantworten Fragen wie:

- Welche Produktbegriffe sollen unverändert bleiben?
- Welche Terminologie sollten wir einheitlich verwenden?
- Welcher Ton passt zu diesem Publikum?
- Welche Sprachentscheidungen sollte ein Agent respektieren bei der Erstellung neuen Materials?

Diese Eingaben können bei der Lokalisierung und bei der Inhaltserstellung in der Quellsprache helfen. Sie beschränken sich nicht nur auf das Abrufen eines passenden Zielsegments.

## Ergänzende Werkzeuge

Übersetzungsspeicher und Sprachführung lösen überlappende, aber unterschiedliche Probleme. Ein Team kann von beiden profitieren. Glossia verspricht nicht, dass modellgenerierter Text jedes geprüfte Segment ersetzen kann, oder dass Prompting sprachliche Korrektheit garantiert.

Die wichtige Architekturwahl besteht darin, einen proprietären Speicher nicht als einzige Autorität für die Sprache des Unternehmens zu machen. Repository-bezogener Inhalt, wiederverwendbarer Kontext, Versionsverlauf und Überprüfung tragen alle zu einem Prozess bei, den das Team verstehen und pflegen kann.

## Kontext benötigt immer noch Überprüfung

Sprachhinweise können unvollständig oder widersprüchlich sein. Ein Begriff kann in verschiedenen Produkten unterschiedliche Bedeutungen haben. Menschen bleiben dafür verantwortlich, zu entscheiden, ob das Ergebnis genau und angemessen ist; Validierung kann strukturelle Fehler erkennen, kann aber nicht beweisen, dass jeder Satz richtig ist.

Lesen Sie [Warum Glossia](./why-glossia) für das breitere Modell und [Kontinuierliche Lokalisierung](./continuous-localization) für die Beziehung zur Lieferung.
