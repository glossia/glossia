%{
  title: "Sprachspeicher und Übersetzungsspeicher",
  summary:
    "Wie Stimme und Terminologie geprüfte Übersetzungen ergänzen, ohne die Lieferung an einen proprietären Speicher zu koppeln.",
  category: "Erklärung",
  markdown_only: true,
  section: "translation",
  order: 4
}
---

Ein Übersetzungsspeicher zeichnet in der Regel zuvor übersetzte Quell-Zielabschnitte auf. Ein passender oder ähnlicher Quellabschnitt kann frühere Arbeit wiederverwenden. Dies ist wertvoll für wiederholendes Material und zur Bewahrung geprüfter Übersetzungen.

Glossias Sprachspeicher adressiert einen weiteren Bedarf: die Prinzipien, die neuem Schreiben den Stil der Organisation verleihen, selbst wenn der Satz noch nie zuvor vorgekommen ist.

## Speichern von Ausgabe versus Speichern von Absicht

Eine geprüfte Übersetzung beantwortet: „Wie haben wir das übersetzt?” Stimmanleitung und ein Glossar beantworten Fragen wie:

- Welche Produktaussagen sollten unverändert bleiben?
- Welche Terminologie sollten wir konsequent verwenden?
- Welcher Ton passt zu dieser Zielgruppe?
- Welche Sprachentscheidungen sollte ein Agent respektieren, wenn er neues Material verfasst?

Diese Eingaben können bei der Lokalisierung und der Inhaltserstellung in der Quellsprache helfen. Sie beschränken sich nicht auf das Abrufen eines passenden Zielsegments.

## Komplementäre Werkzeuge

Übersetzungsspeicher und Sprachführung lösen überlappende aber unterschiedliche Probleme. Ein Team kann von beiden profitieren. Glossia verspricht nicht, dass KI-generierter Text jeden geprüften Abschnitt ersetzen kann, oder dass Prompting Spracherichtigkeit garantiert.

Die wichtige architektonische Entscheidung besteht nicht darin, einen proprietären Speicher als die einzige Autorität für die Sprache des Unternehmens zu machen. Repository-eigener Inhalt, nutzbare Kontexte, Versionshistorie und Prüfung tragen alle zu einem Prozess bei, den das Team verstehen und pflegen kann.

## Kontext benötigt weiterhin Prüfung

Richtlinien können unvollständig oder widersprüchlich sein. Ein Begriff kann in verschiedenen Produkten unterschiedliche Bedeutungen haben. Menschen bleiben dafür verantwortlich, ob das Ergebnis genau und angemessen ist; Validierung kann strukturelle Fehler erfassen, kann aber nicht beweisen, dass jeder Satz richtig ist.

Lesen Sie [Warum Glossia](./why-glossia) für das umfassendere Modell und [Kontinuierliche Lokalisierung](./continuous-localization) für die Beziehung zur Bereitstellung.
