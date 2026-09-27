%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, wenn die Einrichtung einen Fehler meldet.",
  category: "Anleitung",
  section: "Übersetzung",
  order: 4
}
---
Verwenden **Einrichtung wiederholen** nachdem Sie die Bedingung behoben haben, die zum Scheitern der Projekteinrichtung geführt hat.

## 1\. Den Fehler lesen

Öffnen Sie die Projektübersicht. Die Fortschrittskarte der Einrichtung zeigt den Fehler und die neueste Einrichtungsaktivität.

Häufige Ursachen sind:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann auf das Repository nicht zugreifen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## 2\. Die Voraussetzung beheben

Für Modellprobleme, öffnen Sie **Einstellungen** und **Modelle**. Bei Problemen mit dem Zugriff auf das Repository aktualisieren Sie die Glossia GitHub App-Installation in GitHub und gewähren Sie ihr Zugriff auf das Repository.

## 3\. Wiederholen

Zurück zur Projektübersicht und auswählen **Einrichtung wiederholen**.

Die Karte kehrt zurück zu **Ausstehend**, dann **Läuft**, und zeigt neue Aktivitäten an, während die Arbeit fortschreitet. Wiederholen ist nur verfügbar, solange das Projekt im **Fehlgeschlagen** Zustand, der es verhindert, dass zwei Einrichtungsvorgänge gleichzeitig ausgeführt werden.

## 4\. Überprüfung des Abschlusses

Wenn sich der Status ändert auf **Abgeschlossen**. prüfe den resultierenden Pull Request in GitHub. Wenn er erneut fehlschlägt, verwende die neue Aktivität in der Karte anstelle des vorherigen Versuchs, um die nächste Aktion zu identifizieren.