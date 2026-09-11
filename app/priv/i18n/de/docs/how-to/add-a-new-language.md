%{
  title: "Eine neue Sprache hinzufügen",
  summary: "So fügen Sie einer bestehenden Glossia-Einrichtung eine Zielsprache hinzu.",
  category: "Anleitung",
  order: 1
}
---
Wenn Sie Glossia bereits konfiguriert haben und eine weitere Zielsprache hinzufügen möchten, befolgen Sie diese Schritte.

## 1\. Aktualisieren Sie L10N.md

Öffnen Sie Ihre `L10N.md` und fügen Sie den neuen Sprachcode zum `targets` Array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Sprachspezifischen Kontext hinzufügen (optional)

Wenn die neue Sprache spezielle Anweisungen benötigt, z. B. bezüglich des Formalitätsgrads oder der Zeichensatzaspekte, erstellen Sie eine Kontext-Override-Datei:

    L10N/
      ja.md

Schreiben Sie alle sprachspezifischen Hinweise in diese Datei. Glossia kombiniert sie mit dem Basis-Kontext für japanische Übersetzungen.

## 3\. Veröffentlichen Sie die Konfigurationsänderung

Committen und Pushen Sie die aktualisierte Konfiguration. Wenn das Repository mit
Glossia verbunden ist, erkennt der Server die neue Zielsprache und startet eine Übersetzung
Sitzung.

Bestehende Übersetzungen für andere Sprachen bleiben unverändert, wenn ihre Eingaben
und der effektive Kontext unverändert geblieben sind.

## 4\. Überprüfen Sie den Übersetzungs-Pull-Request

Verfolgen Sie die Übersetzungssitzung in Glossia und überprüfen Sie dann die generierte Übersetzung
Dateien im vom Server eröffneten Pull-Request.