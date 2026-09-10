%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Wie man einer bestehenden Glossia-Einrichtung eine Zielsprache hinzufügt.",
  category: "Anleitung",
  order: 1
}
---
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, folgen Sie diesen Schritten.

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

Wenn die neue Sprache spezielle Anweisungen benötigt, wie z. B. den Formalitätsgrad oder den Zeichensatz, erstellen Sie eine Datei zur Kontextüberschreibung:

    L10N/
      ja.md

Schreiben Sie alle sprachspezifischen Hinweise in diese Datei. Glossia kombiniert sie mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Veröffentlichen Sie die Konfigurationsänderung

Commiten und Pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit
Glossia, erkennt der Server die neue Zielsprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und effektiver Kontext nicht geändert wurden.

## 4\. Überprüfen Sie den Übersetzungs-Pull-Request

Folgen Sie der Übersetzungssitzung in Glossia und überprüfen Sie danach die generierte Sprache
Dateien in der vom Server eröffneten Pull-Request.