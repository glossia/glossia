%{
  title: "Inhaltsrevisionierung",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia prüft Quelldateien auf Klarheit, Genauigkeit und Tonfall unter Verwendung des von Ihnen bereitgestellten Kontextes und erstellt dann überarbeitete Versionen, die zur Überprüfung bereitstehen.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tonfall und Klarheit",
      description:
        "Agenten prüfen Ihren Text auf Lesbarkeit, Fachjargon und Konsistenz mit Ihrer Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nichtdestruktiv",
      description:
        "Überarbeitete Inhalte können das Original überschreiben oder an einen separaten Pfad schreiben. Sie haben stets die Kontrolle über das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedback-Schleife",
      description:
        "Überprüfer korrigieren die Ausgabe, aktualisieren den Kontext und jeder Zyklus verringert die Lücke zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---

## Wie Revisionierung funktioniert

Der Agent liest Ihre Quelldateien und den Kontextgraphen und verbindet lokale Anweisungen (`L10N.md`-Dateien im Stammverzeichnis oder in Unterordnern) mit Remote-Kontext (Ihre auf Kontoniveau definierte Stimme, Glossar und Stil-Einstellungen). Sobald das Gesamtbild zusammengefasst ist, umformt der Agent Inhalte für Klarheit, Genauigkeit und Tonfall und gibt die überarbeitete Version bereit für die Überprüfung aus.

## Kontextgraph

Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository umfasst. Kontoniveau-Einstellungen wie Stimme und Glossar bilden eine globale Baseline, während `L10N.md`-Dateien, die neben Ihrem Inhalt platziert sind, lokale Überschreibungen hinzufügen. Der Agent löst diesen Graph bei jedem Durchlauf auf, damit Ihre Anweisungen über alle Dateien hinweg konsistent bleiben, ohne dass Sie sich wiederholen müssen. Überprüfungen sind dank Lockfiles, die verfolgen, was bereits verarbeitet wurde, inkrementell, sodass nur veränderter oder neuer Inhalt erneut bearbeitet wird.

## Progressive Verfeinerung

Jeder Überprüfungsdurchlauf verbessert das Ergebnis. Korrekturen fließen in Kontextdateien zurück, sodass sich wiederholte Fehler auflösen und das Ergebnis über die Zeit auf den Standard Ihres Teams konvergiert.
