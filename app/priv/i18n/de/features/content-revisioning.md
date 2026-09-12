%{
  title: "Inhaltsrevision",
  summary:
    "Verbessern Sie Ihren bestehenden Inhalt direkt. Glossia prüft Quelldateien auf Klarheit, Genauigkeit und Ton unter Verwendung des von Ihnen bereitgestellten Kontexts und erstellt daraufhin überarbeitete Versionen, die zur Prüfung bereitstehen.",
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
        "Überarbeiteter Inhalt kann das Original überschreiben oder an einen separaten Pfad geschrieben werden. Sie bestimmen stets das Ausgabeziel.",
      icon: "shield-check"
    },
    %{
      title: "Feedbackschleife",
      description:
        "Prüfer korrigieren die Ausgabe, aktualisieren den Kontext und jeder Zyklus verringert die Lücke zwischen Entwurf und Endfassung.",
      icon: "refresh-cw"
    }
  ]
}
---
## Wie die Revisionierung funktioniert

Der Agent liest Ihre Quelltexte und den Kontextgraphen und verbindet lokale Anweisungen (`L10N.md`-Dateien im Root-Ordner oder in Unterordnern) mit Remote-Kontext (Ihre auf Kontoebene definierte Stimme, Terminologie und Stileinstellungen). Mit dem vollständigen Bild aktualisiert der Agent den Inhalt zur Klarheit, Genauigkeit und zum Ton und gibt die überarbeitete Version zur Prüfung aus.

## Kontextgraph

Der Kontext in Glossia ist ein Graph, der Ihr Konto und Ihr Repository umfasst. Einstellungen auf Kontoebene wie Stimme und Terminologie bilden eine globale Basis, während `L10N.md`-Dateien, die neben Ihrem Inhalt platziert werden, lokale Überschreibungen hinzufügen. Der Agent verarbeitet diesen Graphen bei jedem Durchlauf, sodass Sie Anweisungen über Dateien hinweg konsistent halten können, ohne sich dabei zu wiederholen. Überprüfungen verlaufen inkrementell dank Lockdateien, die verfolgen, was bereits verarbeitet wurde, sodass nur geänderter oder neuer Inhalt erneut betrachtet wird.

## Progressive Verfeinerung

Jeder Überprüfungszyklus verbessert die Ausgabe. Korrekturen fließen in die Kontextdateien zurück, sodass wiederholte Fehler verschwinden und die Ausgabe Ihrem Teamstandard im Laufe der Zeit annähert.