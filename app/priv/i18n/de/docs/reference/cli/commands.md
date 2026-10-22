%{
  title: "Befehle",
  summary: "Referenz für alle Glossia-Kommandozeilenbefehle und deren Flags.",
  category: "Referenz",
  subcategory: "CLI",
  order: 1
}
---

## `glossia init`

Erstellen Sie eine `L10N.md`-Konfigurationsdatei im aktuellen Repository.

```bash
glossia init
```

Es schlägt fehl, wenn `L10N.md` bereits existiert.

## Die Übersetzung erfolgt serverseitig.

Die Übersetzung läuft im gehosteten Glossia-Dienst anstatt im Befehlszeileninterface. Sobald ein Commit erfolgreich übernommen wurde, plant Glossia die Arbeit anhand Ihrer `L10N.md`-Dateien, übersetzt jede Datei mit dem im Rahmen Ihres Kontos konfigurierten Modell und erstellt eine Pull-Request mit den Ergebnissen. Sie können jede Datei und die Modellwechsel live auf der Übersetzungs-Sitzungsseite beobachten.

Das Modell wird pro Dokument ausgewählt: Eine `L10N.md` `model:`-Anweisung, die eines Ihrer Kontomodell-Handles benannt, wählt es; andernfalls wird das Standardmodell Ihres Kontos verwendet.

Das Befehlszeileninterface plant absichtlich nicht generierte Übersetzungen zu planen, zu übersetzen, zu validieren, zu untersuchen oder zu löschen. Es liest auch keine Übersetzungs-Sperdateien, die von Glossia veröffentlicht wurden.

## `glossia revisit`

Reserviert für einen zukünftigen Quell-Sprachen-Überprüfungsdurchlauf. Die Rust-Befehlszeilenschnittstelle gibt derzeit einen Fehler "nicht implementiert" für diesen Befehl zurück.

```bash
glossia revisit
```

## Globale Optionen

| Option | Beschreibung |
|---|---|
| `--path <PATH>` | Das Projekt-Wurzelverzeichnis überschreiben |
| `--no-color` | Farbige Ausgabe deaktivieren |
