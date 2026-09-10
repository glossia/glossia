%{
  title: "Inhaltsrevision",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia prüft Quelldateien auf Klarheit, Genauigkeit und Tonfall unter Verwendung des von Ihnen bereitgestellten Kontexts und erstellt überarbeitete Fassungen, die zur Überprüfung bereitstehen.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton und Klarheit",
      description:
        "Agenten prüfen Ihren Text auf Lesbarkeit, Jargon und Übereinstimmung mit Ihrer Markenstimme.",
      icon: "message-circle"
    },
    %{
      title: "Nicht-destruktiv",
      description:
        "Überarbeiteter Inhalt kann den Original überschreiben oder in einen separaten Pfad geschrieben werden. Sie haben stets die Kontrolle über das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedbackschleife",
      description:
        "Prüfer korrigieren die Ausgabe, aktualisieren den Kontext, und jeder Zyklus verengt die Lücke zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## Wie Revisionierung funktioniert

Der Agent liest Ihre Quelldateien und den Kontextgraph, verschmilzt lokale Anweisungen (`L10N.md`-Dateien im Stamm- oder in Unterordnern) mit remoter Kontext (Ihre auf Account-Ebene definierte Stimme, Terminologie und Stileinstellungen). Sobald das Gesamtbild vollständig vorliegt, erstellt er den Inhalt für Klarheit, Genauigkeit und Ton neu, und gibt die überarbeitete Version bereit für die Prüfung aus.

## Kontextgraph

Kontext in Glossia ist ein Graph, der Ihren Account und Ihr Repository umfasst. Einstellungen auf Account-Ebene wie Stimme und Terminologie bieten eine globale Basis, während `L10N.md`-Dateien, die neben Ihren Inhalten platziert sind, lokale Überschreibungen hinzufügen. Der Agent löst diesen Graph in jedem Durchlauf auf, sodass Ihre Anweisungen über Dateien hinweg konsistent bleiben, ohne dass Sie sich wiederholen müssen. Überprüfungen sind inkrementell dank Lockdateien, die verfolgen, was bereits verarbeitet wurde, sodass nur geänderter oder neuer Inhalt erneut bearbeitet wird.

## Schrittweise Verfeinerung

Jeder Überprüfungszyklus verbessert das Ergebnis. Korrekturen fließen in Kontextdateien zurück, sodass sich wiederholte Fehler auflösen und das Ergebnis im Laufe der Zeit dem Standard Ihres Teams annähert.