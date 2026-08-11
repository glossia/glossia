%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Wie Sie einem bestehenden Glossia-Setup eine Zielsprache hinzufügen.",
  category: "how-to",
  order: 1
}
---
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1. GLOSSIA.md aktualisieren

Öffnen Sie Ihre `GLOSSIA.md` und fügen Sie den neuen Sprachcode zum Array `targets` hinzu:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen erfordert, wie z. B. den Formalitätsgrad oder Aspekte des Zeichensatzes, erstellen Sie eine Datei zur Kontext-Überschreibung:

```
GLOSSIA/
  ja.md
```

Schreiben Sie alle sprachspezifischen Vorgaben in diese Datei. Glossia führt diese für japanische Übersetzungen mit dem Basis-Kontext zusammen.

## 3. Konfigurationsänderung veröffentlichen

Committen und pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzungssitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn sich deren Eingaben und der effektive Kontext nicht geändert haben.

## 4. Übersetzungs-Pull-Request prüfen

Verfolgen Sie die Übersetzungssitzung in Glossia und prüfen Sie anschließend die generierten Sprachdateien im vom Server geöffneten Pull-Request.