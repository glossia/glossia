%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Wie man eine Zielsprache zu einer bestehenden Glossia-Einrichtung hinzufügt.",
  category: "Anleitung",
  section: "translation",
  order: 1
}
---
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1\. Aktualisieren Sie L10N.md

Öffnen Sie Ihre `L10N.md` und fügen Sie den neuen Sprachcode zum `targets` Array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Fügen Sie sprachspezifischen Kontext hinzu (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie etwa Formalitätsgrad oder Zeichensatz-Aspekte, erstellen Sie eine Kontext-Überschreibungsdatei:

    L10N/
      ja.md

Schreiben Sie alle sprachspezifischen Anweisungen in diese Datei. Glossia kombiniert sie mit dem Basis-Kontext für Übersetzungen ins Japanische.

## 3\. Veröffentlichen Sie die Konfigurationsänderung

Commit und pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit
Glossia, erkennt der Server die neue Zielsprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Inputs
und effektiver Kontext nicht geändert haben.

## 4\. Überprüfen Sie den Übersetzungs-Pull-Request

Verfolgen Sie die Übersetzungssitzung in Glossia und prüfen Sie dann die generierte Sprache.
die Dateien im vom Server geöffneten Pull-Request.