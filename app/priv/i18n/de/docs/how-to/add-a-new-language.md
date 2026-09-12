%{
  title: "Eine neue Sprache hinzufügen",
  summary: "So fügt man einer bestehenden Glossia-Einrichtung eine Zielsprache hinzu.",
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

Wenn die neue Sprache besondere Anweisungen benötigt, wie Formalitätsgrad oder Zeichensatz, erstellen Sie eine Kontext-Überschreibungsdatei:

    L10N/
      ja.md

Schreiben Sie alle sprachspezifischen Hinweise in diese Datei. Glossia verbindet dies mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Konfigurationsänderung veröffentlichen

Commit und Push der aktualisierten Konfiguration. Wenn das Repository mit
Glossia, erkennt der Server die neue Zielsprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und ihr effektiver Kontext unverändert geblieben sind.

## 4\. Übersetzungs-Pull-Request überprüfen

Verfolgen Sie die Übersetzungssitzung in Glossia und überprüfen Sie dann die generierte Sprache
Dateien im vom Server eröffneten Pull-Request.