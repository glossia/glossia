%{
  title: "Inhaltsüberarbeitung",
  summary: "Verbessern Sie Ihre bestehenden Inhalte direkt vor Ort. Glossia überprüft Quelldateien auf Klarheit, Genauigkeit und Tonalität anhand des von Ihnen bereitgestellten Kontexts und erstellt anschließend überarbeitete Versionen, die zur Überprüfung bereitstehen.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Jetzt starten",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Tonfall und Klarheit", description: "Agents überprüfen Ihre Texte auf Lesbarkeit, Fachjargon und Konsistenz mit Ihrer Markenstimme.", icon: "message-circle"},
    %{title: "Zerstörungsfrei", description: "Überarbeitete Inhalte können das Original überschreiben oder in einen separaten Pfad geschrieben werden. Sie behalten stets die Kontrolle über das Ausgabeziel.", icon: "shield-check"},
    %{title: "Feedback-Schleife", description: "Prüfer korrigieren das Ergebnis, aktualisieren den Kontext, und jeder Zyklus verringert den Abstand zwischen Entwurf und Endfassung.", icon: "refresh-cw"}
  ]
}
---
## Funktionsweise der Überarbeitung

Der Agent liest Ihre Quelldateien sowie den Kontextgraphen und führt lokale Anweisungen (`GLOSSIA.md`-Dateien im Stammverzeichnis oder in Unterverzeichnissen) mit dem Remote-Kontext (Ihre Stimme, Terminologie und Stileinstellungen auf Kontoebene) zusammen. Sobald das Gesamtbild vorliegt, schreibt er Inhalte im Hinblick auf Klarheit, Genauigkeit und Tonfall um und gibt die überarbeitete Version aus, die dann zur Überprüfung bereitsteht.

## Kontextgraph

Der Kontext in Glossia ist ein Graph, der sich über Ihr Konto und Ihr Repository erstreckt. Einstellungen auf Kontoebene wie Stimme und Terminologie bieten eine globale Basis, während `GLOSSIA.md`-Dateien, die neben Ihren Inhalten platziert werden, lokale Überschreibungen hinzufügen. Der Agent löst diesen Graphen bei jedem Durchlauf auf, sodass Ihre Anweisungen über alle Dateien hinweg konsistent bleiben, ohne dass Sie sich wiederholen müssen. Überprüfungen erfolgen inkrementell dank Lockfiles, die nachverfolgen, was bereits verarbeitet wurde, sodass nur geänderte oder neue Inhalte erneut geprüft werden.

## Progressive Verfeinerung

Jeder Überprüfungszyklus verbessert das Ergebnis. Korrekturen fließen in die Kontextdateien zurück, sodass sich wiederholende Fehler verschwinden und sich das Ergebnis im Laufe der Zeit dem Standard Ihres Teams annähert.