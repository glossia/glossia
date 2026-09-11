%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, wenn die Einrichtung einen Fehler meldet.",
  category: "Anleitung",
  order: 4
}
---
Verwenden Sie **Setup wiederholen** nach der Behebung der Bedingung, die die Projekteinrichtung zum Scheitern gebracht hat.

## 1\. Fehler einsehen

Öffnen Sie die Projektübersicht. Die Einrichtungsfortschrittskarte zeigt den Fehler und die neueste Einrichtungstätigkeit an.

Häufige Ursachen sind:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann auf das Repository nicht zugreifen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## 2\. Voraussetzung korrigieren

Bei Modellproblemen öffnen Sie **Einstellungen** und **Modelle**. Bei Repository-Zugangsproblemen aktualisieren Sie die Installation der Glossia GitHub App in GitHub und gewähren ihr Zugriff auf das Repository.

## 3\. Wiederholen

Gehen Sie zurück zur Projektübersicht und wählen Sie **Setup wiederholen** aus.

Die Karte kehrt zu **Ausstehend** zurück, dann zu **Laufend**, und zeigt neue Aktivitäten an, sobald die Arbeit fortschreitet. Die Wiederholung ist nur verfügbar, solange das Projekt im **Fehlgeschlagenen** Zustand ist, was verhindert, dass zwei Einrichtungsvorgänge gleichzeitig ausgeführt werden.

## 4\. Abschluss überprüfen

Wenn der Zustand zu **Abgeschlossen** wechselt, prüfen Sie den resultierenden Pull-Request in GitHub. Wenn er erneut fehlschlägt, verwenden Sie die neue Aktivität in der Karte anstelle des vorherigen Versuchs, um die nächste Aktion zu identifizieren.