%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Eine Zielsprache zu einer bestehenden Glossia-Einrichtung hinzufügen.",
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

Wenn die neue Sprache spezielle Anweisungen benötigt, wie etwa zur Formalitätsstufe oder zu Zeichensatz-Aspekten, erstellen Sie eine Kontext-Überschreibdatei:

    L10N/
      ja.md

Schreiben Sie alle sprachspezifischen Hinweise in diese Datei. Glossia kombiniert sie mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Konfigurationsänderung veröffentlichen

Commit und Push der aktualisierten Konfiguration. Wenn das Repository mit
Glossia, erkennt der Server die neue Zielsprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und der effektive Kontext unverändert geblieben sind.

## 4\. Überprüfen Sie den Übersetzungs-Pull-Request

Verfolgen Sie die Übersetzungssitzung in Glossia, und überprüfen Sie dann die generierte Sprache
Dateien in dem vom Server eröffneten Pull-Request.