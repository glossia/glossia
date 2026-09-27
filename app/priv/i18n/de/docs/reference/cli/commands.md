%{
  title: "Befehle",
  summary: "Referenz für alle Glossia-Kommandozeilenbefehle und ihre Flags.",
  category: "Referenz",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Startpunkt erstellen `L10N.md` Konfigurationsdatei im aktuellen Repository.

```bash
glossia init
```

Scheitert, wenn `L10N.md` bereits existiert.

## Übersetzung ist serverseitig

Die Übersetzung läuft auf dem Glossia-Server, nicht in der Kommandozeile. Wenn ein Commit eintrifft,
Glossia plant die Arbeit anhand Ihrer `L10N.md` Dateien, übersetzt jede Datei mit
das bei deinem Konto konfigurierte Modell und erstellt einen Pull-Request mit den Ergebnissen. Du
kannst du jede Datei und die Modell-Antworten live auf der Übersetzungssitzungsseite verfolgen.

Das Modell wird pro Dokument ausgewählt: ein `L10N.md` `model:` wenn du eines deiner
Konto-Modell-Verwalter wählt es aus; andernfalls wird das Standardmodell deines Kontos verwendet.

Die Befehlszeilenschnittstelle plant absichtlich nicht, übersetzt nicht, validiert nicht,
überprüft oder löscht generierte Übersetzungen. Sie liest auch keine Server-
Übersetzungs-Lockfiles.

## `glossia revisit`

Vorbehalten für einen zukünftigen Quellensprachen-Revision-Durchlauf. Die Rust-Befehlszeilen-
Schnittstelle gibt derzeit für diesen Befehl einen nicht implementierten Fehler zurück.

```bash
glossia revisit
```

## Globale Flags

| Flag | Beschreibung |
|---|---|
| `--path <PATH>` | Das Projektwurzelverzeichnis überschreiben |
| `--no-color` | Farbige Ausgabe deaktivieren |