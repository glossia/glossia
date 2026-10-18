%{
  title: "Eine neue Sprache hinzufügen",
  summary: "So fügen Sie einer bestehenden Glossia-Einrichtung eine Zielsprache hinzu.",
  category: "Anleitung",
  section: "translation",
  order: 1
}
---

Wenn Glossia bereits konfiguriert ist und du eine weitere Zielsprache hinzufügen möchtest, folge diesen Schritten.

## 1. L10N.md aktualisieren

Öffne dein `L10N.md` und füge den neuen Sprachcode in das `targets`-Array ein:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, wie zum Beispiel Formalitätslevel oder Zeichensatz-Betrachtungen, erstelle eine Kontext-Überschreibungsdatei:

```
L10N/
  ja.md
```

Schreibe jede sprachspezifische Anleitung in diese Datei. Glossia kombiniert sie mit dem Basiskontext für japanische Übersetzungen.

## 3. Konfigurationsänderung veröffentlichen

Commit und Pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzungs-Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben und der effektive Kontext unverändert sind.

## 4. Übersetzungs-Pull-Request überprüfen

Verfolge die Übersetzungs-Sitzung in Glossia und überprüfe dann die generierten Sprachdateien im vom Server eröffneten Pull-Request.
