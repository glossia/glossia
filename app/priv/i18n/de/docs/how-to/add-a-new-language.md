%{
  title: "Neue Sprache hinzufügen",
  summary: "So fügen Sie einer bestehenden Glossia-Einrichtung eine Zielsprache hinzu.",
  category: "Anleitung",
  section: "translation",
  order: 1
}
---

Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1. L10N.md aktualisieren

Öffnen Sie Ihre `L10N.md` und fügen Sie den neuen Sprachcode dem `targets`-Array hinzu:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie beispielsweise das Formalitätsniveau oder Zeichensatz-Betrachtungen, erstellen Sie eine Kontext-Override-Datei:

```
L10N/
  ja.md
```

Schreiben Sie jegliche sprachspezifische Anleitung in diese Datei. Glossia verbindet sie mit dem Basis-Kontext für japanische Übersetzungen.

## 3. Konfigurationsänderung veröffentlichen

Commit und Pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzungssitzung.

Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben und der effektive Kontext unverändert geblieben sind.

## 4. Übersetzungs-Pull-Request überprüfen

Verfolgen Sie die Übersetzungssitzung in Glossia und überprüfen Sie anschließend die generierten Sprachdateien im vom Server eröffneten Pull-Request.
