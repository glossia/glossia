%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Wie fügt man einer bestehenden Glossia-Konfiguration eine Zielsprache hinzu.",
  category: "Anleitung",
  order: 1
}
---
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1\. L10N.md aktualisieren

Öffnen Sie Ihre `L10N.md` und fügen Sie den neuen Sprachcode zum `targets` Array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie Formalitätsgrad oder Zeichensatz-Betrachtungen, erstellen Sie eine Datei zur Überschreibung des Kontextes:

    L10N/
      ja.md

Schreiben Sie sprachspezifische Hinweise in diese Datei. Glossia kombiniert es mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Veröffentlichen Sie die Konfigurationsänderung

Commit und Push der aktualisierten Konfiguration. Wenn das Repository verbunden ist mit
Glossia, erkennt der Server die neue Zielsprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und der effektive Kontext unverändert sind.

## 4\. Überprüfen Sie den Übersetzungs-Pull-Request

Folgen Sie der Übersetzungssitzung in Glossia und überprüfen Sie danach die generierte Sprache
Dateien im vom Server eröffneten Pull-Request.