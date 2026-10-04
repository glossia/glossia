%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Wie man eine Zielsprache zu einer bestehenden Glossia-Einrichtung hinzufügt.",
  category: "Anleitung",
  section: "translation",
  order: 1
}
---
Wenn Sie bereits Glossia konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, folgen Sie diesen Schritten.

## 1\. L10N.md aktualisieren

Öffnen Sie Ihre `L10N.md` und fügen Sie den neuen Sprachcode dem `targets` Array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Sprachspezifischer Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie z. B. Formalitätsniveau oder Zeichensatz-Aspekte, erstellen Sie eine Datei zur Kontextüberschreibung:

    L10N/
      ja.md

Schreiben Sie alle sprachspezifischen Hinweise in diese Datei. Glossia kombiniert sie mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Veröffentlichen Sie die Konfigurationsänderung

Commiten und Pushen Sie die aktualisierte Konfiguration. Wenn das Repository verbunden ist mit
Glossia, der Server erkennt die neue Ziel-Sprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und der effektive Kontext unverändert geblieben ist.

## 4\. Prüfen Sie den Übersetzungs-Pull-Request

Verfolgen Sie die Übersetzungssitzung in Glossia und prüfen Sie dann die generierte Sprache
Dateien im vom Server geöffneten Pull-Request.