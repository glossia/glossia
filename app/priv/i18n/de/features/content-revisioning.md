%{
  title: "Inhaltsrevision",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia prüft Quelldateien auf Klarheit, Richtigkeit und Ton unter Verwendung des von Ihnen bereitgestellten Kontexts und stellt danach überarbeitete Versionen zur Prüfung bereit.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton und Klarheit",
      description:
        "Agenten prüfen Ihren Text auf Lesbarkeit, Fachbegriffe und Konsistenz mit Ihrer Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nicht-destruktiv",
      description:
        "Überarbeitete Inhalte können das Original überschreiben oder in einen separaten Pfad schreiben. Sie kontrollieren immer das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedback-Schleife",
      description:
        "Prüfer korrigieren das Ergebnis, aktualisieren den Kontext und jeder Zyklus verringert die Lücke zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## Wie Revisionierung funktioniert

Der Agent liest Ihre Quelldateien sowie den Kontextgraphen und kombiniert lokale Anweisungen (`L10N.md`-Dateien im Root-Ordner oder in Unterordnern) mit dem remote Kontext (Ihre kontoebene Einstellungen für Stimme, Terminologie und Stil). Sobald das Gesamtbild zusammengefasst ist, wird der Inhalt zur Klarheit, Genauigkeit und Tonlage überarbeitet und die überarbeitete Version ist zur Überprüfung bereit.

## Kontextgraph

Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository umfasst. Kontoebene-Einstellungen wie Stimme und Terminologie liefern eine globale Basis, während `L10N.md`-Dateien, die neben Ihrem Inhalt platziert sind, lokale Überschreibungen hinzufügen. Der Agent löst diesen Graphen bei jedem Lauf auf, sodass Ihre Anweisungen über Dateien hinweg konsistent bleiben, ohne dass sich diese wiederholen. Überprüfungen sind inkrementell dank Lockdateien, die verfolgen, was bereits verarbeitet wurde, sodass nur veränderte oder neue Inhalte erneut bearbeitet werden.

## Schrittweise Verfeinerung

Jeder Überprüfungsdurchlauf verbessert das Ergebnis. Korrekturen fließen zurück in Kontextdateien, sodass sich wiederholte Fehler auflösen und das Ergebnis im Laufe der Zeit auf Ihren Teamstandard konvergiert.