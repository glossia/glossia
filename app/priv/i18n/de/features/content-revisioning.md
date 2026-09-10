%{
  title: "Inhaltsüberarbeitung",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia prüft Quelldateien auf Klarheit, Genauigkeit und Ton, unter Berücksichtigung des von Ihnen bereitgestellten Kontexts, und erstellt dann überarbeitete Versionen zur Überprüfung.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton und Klarheit",
      description:
        "Agenten prüfen Ihre Texte auf Lesbarkeit, Fachjargon und Konsistenz mit Ihrer Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nicht-zerstörend",
      description:
        "Überarbeitete Inhalte können das Original überschreiben oder an einen separaten Pfad geschrieben werden. Sie haben immer die Kontrolle über das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedbackschleife",
      description:
        "Prüfer korrigieren die Ausgabe, aktualisieren den Kontext, und jeder Zyklus verringert die Lücke zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## Wie Revisionierung funktioniert

Der Agent liest Ihre Quelldateien und den Kontextgraphen, fusioniert lokale Anweisungen (`L10N.md`-Dateien in der Wurzel oder in Unterverzeichnissen) mit dem Remote-Kontext (Ihre kontextuellen Einstellungen für Stimme, Terminologie und Stil auf Kontoebene). Sobald das Gesamtbild vollständig ist, überarbeitet der Agent den Inhalt für Klarheit, Genauigkeit und Ton und gibt die überarbeitete Version für die Überprüfung aus.

## Kontextgraph

Der Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository umspannt. Einstellungen auf Kontoebene wie Stimme und Terminologie bilden eine globale Basis, während `L10N.md`-Dateien, die neben Ihrem Inhalt platziert werden, lokale Überschreibungen hinzufügen. Der Agent verarbeitet diesen Graph bei jedem Durchlauf, sodass Ihre Anweisungen konsistent über Dateien hinweg bleiben, ohne dass Sie sich wiederholen müssen. Überprüfungen erfolgen inkrementell dank Lockdateien, die verfolgen, was bereits verarbeitet wurde, sodass nur geänderter oder neuer Inhalt erneut bearbeitet wird.

## Progressive Verfeinerung

Jeder Überprüfungsdurchlauf verbessert die Ausgabe. Korrekturen fließen in Kontextdateien zurück, sodass sich wiederholte Fehler auflösen und die Ausgabe sich im Laufe der Zeit an den Standard Ihres Teams anpasst.