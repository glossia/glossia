%{
  title: "Inhaltsrevision",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia überprüft Quelldateien auf Klarheit, Genauigkeit und Ton unter Verwendung des von Ihnen bereitgestellten Kontextes und erstellt daraufhin überarbeitete Versionen, die zur Prüfung bereit sind.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton und Klarheit",
      description:
        "Agenten überprüfen Ihren Text auf Lesbarkeit, Fachjargon und Konsistenz mit Ihrer Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nicht-destruktiv",
      description:
        "Überarbeiteter Inhalt kann das Original überschreiben oder in einen separaten Pfad schreiben. Sie bestimmen stets das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedback-Schleife",
      description:
        "Prüfer korrigieren die Ausgabe, aktualisieren den Kontext und jeder Zyklus verringert den Abstand zwischen Entwurf und Finalfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## So funktioniert die Revisionierung

Der Agent liest Ihre Quelldateien und den Kontextgraphen und fusioniert darin lokale Anweisungen (`L10N.md`-Dateien im Stammverzeichnis oder in Unterordnern) mit dem Remote-Kontext (Ihre auf Kontoebene definierte Stimme, das Glossar und Stil-Einstellungen). Sobald das Gesamtbild zusammengestellt ist, überarbeitet der Agent den Inhalt für Klarheit, Genauigkeit und Ton und liefert eine für die Überprüfung bereitgestellte, überarbeitete Version.

## Kontextgraph

Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository umspannt. Einstellungen auf Kontoebene wie Stimme und Glossar liefern eine globale Basislinie, während `L10N.md`-Dateien, die neben Ihren Inhalten platziert werden, lokale Überschreibungen hinzufügen. Der Agent löst diesen Graph bei jeder Ausführung auf, sodass Ihre Anweisungen über Dateien hinweg konsistent bleiben, ohne sich zu wiederholen. Überprüfungen sind dank Lockfiles, die verfolgen, was bereits verarbeitet wurde, inkrementell, sodass nur veränderte oder neue Inhalte erneut bearbeitet werden.

## Progressive Verfeinerung

Jeder Überprüfungsrunde verbessert die Ausgabe. Korrekturen fließen in Kontextdateien zurück, sodass sich wiederholende Fehler auflösen und die Ausgabe im Laufe der Zeit auf den Standard Ihres Teams konvergiert.