%{
  title: "Befehle",
  summary: "Referenz für alle Glossia Kommandozeilenbefehle und deren Flags.",
  category: "Referenz",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Erstellen Sie eine Start-`L10N.md` Konfigurationsdatei im aktuellen Repository.

```bash
glossia init
```

Scheitert, wenn`L10N.md` bereits existiert.

## Die Übersetzung erfolgt serverseitig

Die Übersetzung wird auf dem Glossia-Server ausgeführt und nicht im Terminal. Sobald ein Commit erstellt wird,
plant Glossia die Arbeit basierend auf Ihren `L10N.md` Dateien und übersetzt jede Datei mit
dem von Ihrem Account konfigurierten Modell und erzeugt einen Pull-Request mit den Ergebnissen. Sie
knnen jede Datei und die Modellrunden live auf der Übersetzungssitzungsseite beobachten.

Das Modell wird pro Dokument gewählt: ein `L10N.md` `model:` Benennungen eines Ihrer
kontextuellen account model wählt aus; sonst wird das Standardmodell Ihres Kontos verwendet.

Die Befehlszeilenoberfläche plant, übersetzt, validiert,
überprüft oder löscht generierte Übersetzungen. Sie liest auch nicht die Server's
Übersetzungsslackfiles.

## `glossia revisit`

Vorbehaltlich einer zukünftigen Quellsprach-Prüfung. Die Rust-Befehlszeilen
Oberfläche gibt aktuell einen nicht-umgesetzten Fehler für diesen Befehl aus.

```bash
glossia revisit
```

## Globale Flags

| Flag | Beschreibung |
|---|---|
| `--path <PATH>` | Das Projektwurzverzeichnis überschreiben |
| `--no-color` | Farbiges Output deaktivieren |