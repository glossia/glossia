%{
  title: "Befehle",
  summary: "Referenz für alle Glossia-Kommandozeilenbefehle und deren Flags.",
  category: "Referenz",
  subcategory: "CLI",
  order: 1
}
---

## `glossia init`

Erstellen Sie eine `L10N.md`-Konfigurationsdatei als Startvorlage im aktuellen Repository.

```bash
glossia init
```

Fehlt, wenn `L10N.md` bereits existiert.

## Übersetzung läuft serverseitig

Die Übersetzung läuft im gehosteten Glossia-Dienst, nicht in der Befehlszeilenschnittstelle. Wenn ein Commit eingeht, plant Glossia die Arbeit aus Ihren `L10N.md`-Dateien, übersetzt jede Datei mit dem vom Konto konfigurierten Modell und erstellt einen Pull-Request mit den Ergebnissen. Sie können jede Datei und die Modell-Verläufe live auf der Überseteilig-Session-Seite verfolgen.

Das Modell wird pro Dokument ausgewählt: eine `L10N.md`-Zeile mit `model:`, die eine der Modell-Handles Ihres Kontos benennt, wählt es aus; ansonsten wird das Standardmodell Ihres Kontos verwendet.

Die Befehlszeilenschnittstelle plant, übersetzt, validiert, inspiziert oder löschtda es nicht absichtlich nicht vorgesehen ist. Zudem liest sie auch nicht die Übersetzungs-Sperrdateien, die von Glossia veröffentlicht werden.

## `glossia revisit`

Vorbehältlich für eine zukünftige Quellsprachen-Überarbeitung. Die Rust-Befehlszeilenschnittstelle liefert derzeit einen 'not-implemented'-Fehler für diesen Befehl.

```bash
glossia revisit
```

## Globale Flags

| Flag | Beschreibung |
|---|---|
| `--path <PATH>` | Ordner des Projektroot überschreiben |
| `--no-color` | Farbige Ausgabe deaktivieren |
