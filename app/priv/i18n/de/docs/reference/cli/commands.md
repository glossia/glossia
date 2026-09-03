%{
  title: "Befehle",
  summary: "Referenz für alle Glossia-Kommandozeilenbefehle und deren Flags.",
  category: "Referenz",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Erstellen Sie eine Start-`GLOSSIA.md`Konfigurationsdatei im aktuellen Repository.

```bash
glossia init
```

Schlägt fehl, wenn`GLOSSIA.md`diese bereits existiert.

## Übersetzung läuft serverseitig

Die Übersetzung läuft auf dem Glossia-Server statt in der Kommandozeile. Wenn ein Commit eintrifft,
Glossia plantet die Arbeiten aus Ihren `GLOSSIA.md`Dateien, übersetzt jede Datei mit
konfiguriertes Modell Ihres Kontos, erstellt einen Pull Request mit den Ergebnissen. Sie
können jede Datei und die Live-Modellwechsel auf der Übersetzungssitzungsseite beobachten.

Das Modell wird pro Dokument gewählt: ein`GLOSSIA.md` `model:`benennt eines Ihrer
Kontomodell-Handles wählt es aus; sonst wird Ihr Standard-Kontomodell verwendet.

Die Kommandozeile plant absichtlich nicht, übersetzt nicht, validiert,
überprüft oder löscht generierte Übersetzungen. Auch liest sie nicht die Server-
Übersetzungs-Lockfiles.

## `glossia revisit`

Vorbehaltlich einer zukünftigen Quellsprachen-Überarbeitungsdurchgang. Die Rust-Kommandozeile
Grenze kehrte derzeit einen nicht implementierten Fehler für diesen Befehl zurück.

```bash
glossia revisit
```

## Globale Optionen

| Option | Beschreibung |
|---|---|
| `--path <PATH>` | Projekt Wurzelverzeichnis überschreiben |
| `--no-color` | Zugriff auf farbige Ausgabe deaktivieren |