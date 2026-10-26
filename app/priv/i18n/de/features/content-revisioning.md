%{
  title: "Content-Überarbeitung",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia prüft Quelldateien auf Klarheit, Genauigkeit und Ton unter Verwendung des von Ihnen bereitgestellten Kontexts und erstellt überarbeitete Versionen, die zur Prüfung bereitstehen.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton und Klarheit",
      description:
        "Agenten prüfen Ihre Texte auf Lesbarkeit, Jargon und Übereinstimmung mit Ihrer Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nicht-destruktiv",
      description:
        "Überarbeitete Inhalte können das Original überschreiben oder an einen separaten Pfad geschrieben werden. Sie haben stets die Kontrolle über das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedback-Schleife",
      description:
        "Begutachter korrigieren die Ausgabe, aktualisieren den Kontext, und jeder Zyklus verringert die Lücke zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---

## So funktioniert die Revisierung

Der Agent liest Ihre Quelldateien und den Kontextgraphen, wobei er lokale Anweisungen (`L10N.md`-Dateien am Stammverzeichnis oder in Unterordnern) mit fernem Kontext (Stimme, Glossar und Stileinstellungen auf Kontenebene) zusammenführt. Wenn das Gesamtbild gebildet wurde, überarbeitet er den Inhalt für Klarheit, Genauigkeit und Ton, und gibt die überarbeitete Version bereit für die Überprüfung aus.

## Kontextgraph

Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository verbindet. Kontenebene-Einstellungen wie Stimme und Glossar bieten eine globale Basislinie, während `L10N.md`-Dateien, die neben Ihrem Inhalt platziert sind, lokale Überschreibungen hinzufügen. Der Agent löst diesen Graph bei jedem Durchlauf auf, damit Ihre Anweisungen über alle Dateien hinweg konsistent bleiben und Sie sich nicht wiederholen. Reviews sind inkrementell dank Lockfiles, die verfolgen, was bereits verarbeitet wurde, sodass nur geänderte oder neue Inhalte erneut durchlaufen werden.

## Schrittweise Verfeinerung

Jeder Reviews-Zyklus verbessert die Ausgabe. Richtigstellungen fließen zurück in Kontextdateien, sodass wiederholte Fehler verschwinden und die Ausgabe im Laufe der Zeit zu Ihrem Teamstandard konvergiert.
