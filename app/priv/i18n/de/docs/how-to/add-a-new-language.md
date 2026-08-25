
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1. GLOSSIA.md aktualisieren

Öffnen Sie Ihre `GLOSSIA.md` und fügen Sie den neuen Sprachcode dem `targets` Array hinzu:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie Formalitätsgrad oder Zeichensatzüberlegungen, erstellen Sie eine Kontext-Überschreibungsdatei:

```
GLOSSIA/
  ja.md
```

Schreiben Sie darin weitere sprachspezifische Anleitungen. Glossia kombiniert dies mit dem Basis-Kontext für Japanisch-Übersetzungen.

## 3. Die Konfigurationsänderung veröffentlichen

Kommiten und pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzungssitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn Ihre Eingaben und der effektive Kontext unverändert sind.

## 4. Die Übersetzungs-Pull-Request überprüfen

Folgen Sie der Übersetzungssitzung in Glossia und beziehen Sie dann die generierten Sprachdateien im vom Server eröffneten Pull-Request mit.