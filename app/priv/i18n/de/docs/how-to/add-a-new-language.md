%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Wie fügt man einer bestehenden Glossia-Einrichtung eine Zielsprache hinzu.",
  category: "Anleitung",
  order: 1
}
---
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie die folgenden Schritte.

## 1\. L10N.md aktualisieren

Öffnen Sie Ihre `L10N.md` und fügen Sie den neuen Sprachcode in das `targets` Array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie etwa Höflichkeitsgrad oder Zeichensatz-Überlegungen, erstellen Sie eine Kontext-Override-Datei:

    L10N/
      ja.md

Schreiben Sie jede sprachspezifische Anleitung in diese Datei. Glossia kombiniert sie mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Veröffentlichen Sie die Konfigurationsänderung

Erstellen Sie einen Commit und pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit
Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzungs
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und der effektive Kontext nicht geändert wurden.

## 4\. Überprüfen Sie den Übersetzungs-Pull-Request

Verfolgen Sie die Übersetzungssitzung in Glossia und prüfen Sie dann die generierte Übersetzung.
Dateien im vom Server eröffneten Pull-Request.