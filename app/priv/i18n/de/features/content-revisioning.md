%{
  title: "Inhaltsrevision",
  summary:
    "Verbessere deinen bestehenden Inhalt direkt. Glossia überprüft Quellendateien auf Klarheit, Genauigkeit und Tonfall unter Verwendung deines bereitgestellten Kontexts und erstellt überarbeitete Versionen zur Überprüfung bereit.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tonalität und Klarheit",
      description:
        "Agenten überprüfen deinen Text auf Lesbarkeit, Fachjargon und Konsistenz mit deiner Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nicht-destruktiv",
      description:
        "Überarbeitete Inhalte können die Originaldatei überschreiben oder an einen anderen Pfad geschrieben werden. Du kontrollierst immer das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Rückkopplungsschleife",
      description:
        "Prüfer korrigieren das Ergebnis, aktualisieren den Kontext und verringern mit jedem Zyklus die Lücke zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## Wie Revisionierung funktioniert

Der Agent liest Ihre Quelldateien und den Kontextgraphen und vereinigt lokale Anweisungen (`GLOSSIA.md`-Dateien im Root-Verzeichnis oder in Unterordnern) mit dem Remote-Kontext (Ihre kontenweiten Einstellungen für Stimme, Terminologie und Stil). Sobald das Gesamtbild vorliegt, schreibt er den Inhalt für Klarheit, Genauigkeit und Ton um und gibt die überarbeitete Version für die Überprüfung aus.

## Kontextgraph

Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository umfasst. Kontenweite Einstellungen wie Stimme und Terminologie bilden eine globale Basisvorlage, während `GLOSSIA.md`-Dateien, die neben Ihrem Inhalt platziert sind, lokale Overrides hinzufügen. Der Agent löst diesen Graphen bei jeder Ausführung auf, sodass Ihre Anweisungen über Dateien hinweg konsistent bleiben, ohne dass Sie sich wiederholen müssen. Überprüfungen sind inkrementell dank Lockdateien, die verfolgen, was bereits verarbeitet wurde, sodass nur veränderte oder neue Inhalte erneut betrachtet werden.

## Progressive Verfeinerung

Jeder Überprüfungszyklus verbessert die Ausgabe. Korrekturen fließen zurück in Kontextdateien, sodass wiederholte Fehler verschwinden und das Ergebnis mit der Zeit zum Standard Ihres Teams konvergiert.