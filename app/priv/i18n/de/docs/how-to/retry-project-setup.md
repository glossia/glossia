%{
  title: "Projekt-Einrichtung wiederholen",
  summary: "Ein Projekt wiederherstellen, nachdem die Einrichtung einen Fehler gemeldet hat.",
  category: "Anleitungen",
  order: 4
}
---
Verwenden Sie **die Einrichtung erneut versuchen** nach Behebung der Ursache, die die Projekt-Einrichtung zum Scheitern führte.

## 1\. Den Fehler lesen

Öffnen Sie die Projektübersicht. Die Einrichtung-Fortschrittskarte zeigt den Fehler und die neueste Einrichtungstätigkeit.

Häufige Ursachen sind:

- Das Konto hat kein konfiguriertes Modell.
- Der Anbieter-Schlüssel fehlt oder ist ungültig.
- Die Glossia GitHub App kann auf das Repository nicht zugreifen.
- Das Repository konnte nicht vorbereitet oder geprüft werden.

## 2\. Voraussetzung beheben

Für Modellprobleme öffnen **Einstellungen** und **Modelle**. Für Probleme beim Repository-Zugriff aktualisieren Sie die Glossia GitHub App-Installation in GitHub und gewähren Sie ihr den Zugriff auf das Repository.

## 3\. Wiederholen

Zurück zur Projektübersicht und auswählen **Einrichtung wiederholen**.

Die Karte kehrt zu **Ausstehend**, dann **Laufend**und zeigt neue Aktivitäten an, während die Arbeit fortschreitet. Der Neustart ist nur verfügbar, solange das Projekt im **Fehlgeschlagen** Zustand, der verhindert, dass zwei Einrichtungsversuche gleichzeitig ausgeführt werden.

## 4\. Überprüfung der Fertigstellung

Wenn der Zustand wechselt auf **Abgeschlossen**, überprüfen Sie den resultierenden Pull-Request in GitHub. Wenn er erneut fehlschlägt, verwenden Sie die neue Aktivität in der Karte statt des vorherigen Versuchs, um die nächste Aktion zu identifizieren.