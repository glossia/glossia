%{
  title: "Projekteinrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, nachdem die Einrichtung einen Fehler gemeldet hat.",
  category: "how-to",
  order: 4
}
---
Verwenden Sie **Setup wiederholen**, nachdem Sie die Ursache behoben haben, die zum Fehlschlagen einer Projekteinrichtung geführt hat.

## 1. Fehlermeldung lesen

Öffnen Sie die Projektübersicht. Die Karte für den Einrichtungsfortschritt zeigt den Fehler und die letzte Einrichtungsaktivität an.

Häufige Ursachen sind:

- Für das Konto ist kein Modell konfiguriert.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann nicht auf das Repository zugreifen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## 2. Voraussetzung beheben

Öffnen Sie bei Modellproblemen die **Einstellungen** und **Modelle**. Aktualisieren Sie bei Problemen mit dem Repository-Zugriff die Installation der Glossia GitHub App in GitHub und gewähren Sie ihr Zugriff auf das Repository.

## 3. Erneut versuchen

Kehren Sie zur Projektübersicht zurück und wählen Sie **Setup wiederholen**.

Die Karte wechselt zurück zu **Ausstehend**, dann zu **Wird ausgeführt** und zeigt bei fortschreitender Arbeit neue Aktivitäten an. Der erneute Versuch ist nur verfügbar, wenn sich das Projekt im Status **Fehlgeschlagen** befindet. Dies verhindert, dass zwei Einrichtungsversuche gleichzeitig ausgeführt werden.

## 4. Abschluss überprüfen

Wenn der Status zu **Abgeschlossen** wechselt, überprüfen Sie den resultierenden Pull Request in GitHub. Falls er erneut fehlschlägt, nutzen Sie die neue Aktivität auf der Karte anstelle des vorherigen Versuchs, um den nächsten Schritt zu bestimmen.