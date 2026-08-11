%{
  title: "Befehle",
  summary: "Referenz für alle Glossia-Befehlszeilenbefehle und deren Flags.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Erstellt eine anfängliche `GLOSSIA.md`-Konfigurationsdatei im aktuellen Repository.

```bash
glossia init
```

Schlägt fehl, wenn `GLOSSIA.md` bereits existiert.

## Übersetzung erfolgt serverseitig

Die Übersetzung wird auf dem Glossia-Server ausgeführt, nicht in der Kommandozeilenschnittstelle. Wenn ein Commit eingereicht wird, plant Glossia die Arbeit auf Basis Ihrer `GLOSSIA.md`-Dateien, übersetzt jede Datei mit dem für Ihr Konto konfigurierten Modell und öffnet einen Pull Request mit den Ergebnissen. Sie können jede Datei und die Interaktionsschritte des Modells live auf der Seite der Übersetzungssitzung mitverfolgen.

Das Modell wird pro Dokument ausgewählt: Ein `GLOSSIA.md` `model:`, das eines der Modell-Handles Ihres Kontos angibt, wählt dieses aus; andernfalls wird das Standardmodell Ihres Kontos verwendet.

Die Kommandozeilenschnittstelle plant, übersetzt, validiert, prüft oder löscht generierte Übersetzungen bewusst nicht. Sie liest auch nicht die Übersetzungs-Sperrdateien des Servers.

## `glossia revisit`

Reserviert für einen zukünftigen Revisionsdurchlauf der Quellsprache. Die Rust-Kommandozeilenschnittstelle gibt derzeit für diesen Befehl einen Fehler bezüglich einer nicht implementierten Funktion zurück.

```bash
glossia revisit
```

## Globale Flags

| Flag | Beschreibung |
|---|---|
| `--path <PATH>` | Das Projekt-Stammverzeichnis überschreiben |
| `--no-color` | Farbige Ausgabe deaktivieren |