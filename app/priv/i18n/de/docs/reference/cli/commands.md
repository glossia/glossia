%{
  title: "Befehle",
  summary: "Referenz für alle Glossia-CLI-Befehle und deren Schalter.",
  category: "Referenz",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Erstellen Sie eine Start`L10N.md` Konfigurationsdatei im aktuellen Repository.

```bash
glossia init
```

Fehlt, wenn`L10N.md` bereits existiert.

## Die Übersetzung erfolgt serverseitig

Die Übersetzung wird auf dem Glossia-Server, nicht in der Kommandozeilenschnittstelle ausgeführt. Wenn ein Commit landet,
plant Glossia die Arbeit basierend auf Ihren`L10N.md` Dateien, übersetzt jede Datei mit
dem auf Ihrem Konto konfigurierten Modell und eröffnet einen Pull Request mit den Ergebnissen. Sie
können jede Datei und die Schritte des Modells live auf der Übersetzungssitzungsseite verfolgen.

Das Modell wird pro Dokument gewählt: ein`L10N.md` `model:` definiert eines Ihrer
Kontomodell-Handle wählt es aus; ansonsten wird das Standardmodell Ihres Kontos verwendet.

Die Kommandozeilenschnittstelle plant, übersetzt, validates,
prüft oder löscht generierte Übersetzungen nicht. Sie liest zudem nicht die Server-
Übersetzungs-Sperdateien.

## `glossia revisit`

Vervorbehalten für eine zukünftige Revision des Quellen-Sprach-Passes. Die Rust-Kommandozeilenschnittstelle
gibt für diesen Befehl aktuell eine nicht-implementierte Fehlermeldung zurück.

```bash
glossia revisit
```

## Globale Optionen

| Option | Beschreibung |
|---|---|
| `--path <PATH>` | Ersetzen Sie das Projektwurzelverzeichnis |
| `--no-color` | Farbe in der Ausgabe deaktivieren |