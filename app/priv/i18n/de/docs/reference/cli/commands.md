%{
  title: "Befehle",
  summary: "Referenz für alle Glossia-Befehlszeilenbefehle und deren Optionen.",
  category: "Referenz",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Erstellen einer Startvorlage `L10N.md` Konfigurationsdatei im aktuellen Repository.

```bash
glossia init
```

Fehlschlägt, wenn `L10N.md` bereits existiert.

## Die Übersetzung läuft serverseitig

Die Übersetzung läuft im gehosteten Glossia-Service, nicht in der Befehlszeilenschnittstelle. Wenn ein Commit landet,
Glossia plant die Arbeit basierend auf deinen `L10N.md` Dateien, übersetzt jede Datei mit
das für dein Konto konfigurierte Modell und erstellt einen Pull-Request mit den Ergebnissen. Du
kannst du jede Datei und die Modelldurchläufe live auf der Übersetzungssitzungsseite beobachten.

Das Modell wird pro Dokument ausgewählt: eine `L10N.md` `model:` Benennung eines deines
Kontomodell wählt es aus; ansonsten wird das Standardmodell deines Kontos verwendet.

Die Befehlszeilenschnittstelle plant absichtlich nicht, übersetzt nicht, validiert nicht,
überprüft oder löscht generierte Übersetzungen. Sie liest ebenfalls keine von Glossia veröffentlichten Übersetzungs-Sperrdateien.

## `glossia revisit`

Vorarbeitsbereit für einen zukünftigen Quellsprachen-Revisionsdurchlauf. Die Rust-Befehlszeilenschnittstelle
Das Interface gibt für diesen Befehl aktuell einen 'nicht implementierten' Fehler zurück.

```bash
glossia revisit
```

## Globale Flags

| Flag | Beschreibung |
|---|---|
| `--path <PATH>` | Projektverzeichnis überschreiben |
| `--no-color` | Farbige Ausgabe deaktivieren |