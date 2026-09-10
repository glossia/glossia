%{
  title: "Inhaltsrevision",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia prüft Quelldateien auf Klarheit, Genauigkeit und Tonfall unter Verwendung des von Ihnen bereitgestellten Kontexts und erstellt überarbeitete Versionen, die zur Prüfung bereitstehen.",
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
      title: "Nicht-destruktiv",
      description:
        "Überarbeitete Inhalte können den Original überschreiben oder an einen separaten Speicherort geschrieben werden. Sie haben stets die Kontrolle über das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedback-Schleife",
      description:
        "Überprüfer korrigieren das Ergebnis, aktualisieren den Kontext und jeder Zyklus verringert den Abstand zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## Wie Revisionierung funktioniert

Der Agent liest deine Quelldateien und den Kontextgraphen, kombiniert dabei lokale Anweisungen (`L10N.md`-Dateien im Stammverzeichnis oder in Unterordnern) mit Remote-Kontext (deine kontenweiten Einstellungen für Stimme, Terminologie und Stil). Sobald das Gesamtbild zusammengefasst ist, schreibt es den Inhalt für Klarheit, Genauigkeit und Tonfall neu und stellt die überarbeitete Version zur Überprüfung bereit.

## Kontextgraph

Kontext in Glossia ist ein Graph, der dein Konto und dein Repository umfasst. Kontenweite Einstellungen wie Stimme und Terminologie bilden eine globale Basis, während `L10N.md`-Dateien, die neben deinem Inhalt stehen, lokale Überschreibungen hinzufügen. Der Agent löst diesen Graph bei jedem Durchlauf auf, sodass deine Anweisungen über alle Dateien hinweg konsistent bleiben, ohne dass du dich wiederholen musst. Überprüfungen sind dank Sperrdateien inkrementell, die verfolgen, was bereits verarbeitet wurde, sodass nur geänderter oder neuer Inhalt erneut bearbeitet wird.

## Progressive Verfeinerung

Jeder Überprüfungslauf verbessert das Ergebnis. Korrekturen fließen in Kontextdateien zurück, sodass wiederholte Fehler verschwinden und das Ergebnis über die Zeit zum Standard deines Teams konvergiert.