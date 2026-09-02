%{
  title: "Eine neue Sprache hinzufügen",
  summary: "So fügt man eine Zielsprache zu einer bestehenden Glossia-Einrichtung hinzu.",
  category: "how-to",
  order: 1
}
---
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1\. GLOSSIA.md aktualisieren

Öffnen Sie Ihr `GLOSSIA.md` und fügen Sie den neuen Sprachcode zum `targets` Array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Zielsprache spezielle Anweisungen benötigt, wie z. B. den Formalitätsgrad oder Zeichensatz-Anpassungen, erstellen Sie eine Kontext-Override-Datei:

    GLOSSIA/
      ja.md

Schreiben Sie jede sprachspezifische Anleitung in diese Datei. Glossia verschmilzt es mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Veröffentlichen Sie die Konfigurationsänderung

Comitieren und Pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit
Glossia, erkennt der Server die neue Zielsprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und effektiver Kontext nicht geändert wurden.

## 4\. Überprüfen Sie den Übersetzungs-Pull-Request

Folgen Sie der Übersetzungssitzung in Glossia und überprüfen Sie anschließend die generierten Sprach-
dateien im vom Server eröffneten Pull-Request.