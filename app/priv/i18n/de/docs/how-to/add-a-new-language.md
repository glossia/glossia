%{
  title: "Eine neue Sprache hinzufügen",
  summary: "Wie man einer bestehenden Glossia-Einrichtung eine Zielsprache hinzufügt.",
  category: "how-to",
  section: "translation",
  order: 1
}
---

Falls Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1. Aktualisieren Sie L10N.md

Öffnen Sie Ihr `L10N.md` und fügen Sie den neuen Sprachcode in das `targets` Array ein:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Fügen Sie sprachspezifischen Kontext hinzu (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt (z. B. Formalitätsniveau oder Zeichensatz-Aspekte), erstellen Sie eine Kontext-Override-Datei:

```
L10N/
  ja.md
```

Schreiben Sie alle sprachspezifischen Anweisungen in diese Datei. Glossia kombiniert sie mit dem Basis-Kontext für Japanische Übersetzungen.

## 3. Veröffentlichen Sie die Konfigurationsänderung

Commit und Pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzungssitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben und der effektive Kontext unverändert geblieben sind.

## 4. Überprüfen Sie den Übersetzungs-Pull-Request

Folgen Sie der Übersetzungssitzung in Glossia und überprüfen Sie dann die generierten Sprachdateien im von dem Server geöffneten Pull-Request.
