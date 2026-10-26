%{
  title: "Neue Sprache hinzufügen",
  summary: "So fügt man einer bestehenden Glossia-Einrichtung eine Zielsprache hinzu.",
  category: "Anleitung",
  section: "translation",
  order: 1
}
---

Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1. L10N.md aktualisieren

Öffnen Sie `L10N.md` und fügen Sie den neuen Sprachcode zum `targets`-Array hinzu:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie beispielsweise das Formalitätsniveau oder die Betrachtungen zum Zeichensatz, erstellen Sie eine Datei zum Überschreiben des Kontextes:

```
L10N/
  ja.md
```

Verfassen Sie jegliche sprachspezifischen Hinweise in diese Datei. Glossia verschmilzt sie mit dem Basis-Kontext für japanische Übersetzungen.

## 3. Konfigurationsänderung veröffentlichen

Committen und pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzungssitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben und der effektive Kontext nicht geändert wurden.

## 4. Überprüfung des Übersetzungs-Pull Requests

Verfolgen Sie die Übersetzungssitzung in Glossia und überprüfen Sie dann die generierten Sprachdateien in dem vom Server eröffneten Pull Request.
