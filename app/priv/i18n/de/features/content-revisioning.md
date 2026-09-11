%{
  title: "Inhaltsrevision",
  summary:
    "Verbessern Sie Ihre bestehenden Inhalte direkt. Glossia prüft Quelldateien auf Klarheit, Genauigkeit und Ton unter Verwendung Ihres Kontexts und erstellt revidierte Versionen zur Überprüfung.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton und Klarheit",
      description:
        "Agenten überprüfen Ihre Texte auf Lesbarkeit, Fachbegriffe und Konsistenz Ihrer Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nicht-zerstörend",
      description:
        "Überarbeitete Inhalte können Originale überschreiben oder an einen separaten Pfad geschrieben werden. Sie bestimmen stets das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedback-Loop",
      description:
        "Rezensenten korrigieren das Ergebnis, aktualisieren den Kontext und jeder Zyklus verringert die Kluft zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## Wie Revisionierung funktioniert

Der Agent liest Ihre Quelldateien und den Kontextgraphen. Lokale Anweisungen (`L10N.md`-Dateien in der Wurzel oder in Unterordnern) werden mit entferntem Kontext (Ihre auf Kontoebene festgelegten Sprechweise-, Terminologie- und Stil-Einstellungen) verschmolzen. Sobald das vollständige Bild zusammengebaut ist, wird Inhalt für Klarheit, Genauigkeit und Tonfall neu geschrieben, und die überarbeitete Version ist bereit für die Überprüfung.

## Kontextgraph

Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository umfasst. Einstellungen auf Kontoebene wie Sprechweise und Terminologie bilden eine globale Basis, während `L10N.md`-Dateien, die sich neben Ihrem Inhalt befinden, lokale Überschreibungen hinzufügen. Der Agent verarbeitet diesen Graph bei jedem Durchlauf, sodass Ihre Anweisungen konsistent über Dateien hinweg bleiben, ohne dass Sie sich unnötig wiederholen müssen. Überprüfungen erfolgen inkrementell dank Sperrdateien, die verfolgen, was bereits verarbeitet wurde, damit nur geänderter oder neuer Inhalt erneut bearbeitet wird.

## Progressive Verfeinerung

Jeder Überprüfungszklus verbessert die Ausgabe. Korrekturen fließen in Kontextdateien zurück, sodass sich wiederholende Fehler auflösen und die Ausgabe sich über die Zeit auf den Standard Ihres Teams konvergiert.