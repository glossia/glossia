%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Projekt nach Einrichtung-Fehler wiederherstellen.",
  category: "Anleitung",
  order: 4
}
---
Verwende **Einrichtung erneut versuchen** nach Behebung der Ursache, die den Projekteinrichtungsversuch gescheitert hat.

## 1\. Fehler lesen

Öffne die Projektübersicht. Die Einrichtung-Fortschrittskarte zeigt den Fehler und die neueste Einrichtungstätigkeit an.

Häufige Ursachen sind:

- Das Konto hat kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist ungültig.
- Die Glossia GitHub App kann nicht auf das Repository zugreifen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## 2\. Beheben Sie die Voraussetzung

Für Modellprobleme öffnen Sie **Einstellungen** und **Modelle**. Für Probleme mit dem Repository-Zugriff aktualisieren Sie die Glossia GitHub App-Installation in GitHub und gewähren Sie ihr Zugriff auf das Repository.

## 3\. Neuversuchen

Zurück zur Projektübersicht und auswählen **Setup neuversuchen**.

Die Karte kehrt zurück zu **Ausstehend**, dann **Läuft**, und zeigt neue Aktivitäten an, während die Arbeit weitergeht. Die Wiederholung ist nur verfügbar, solange sich das Projekt im **Fehlgeschlagen** Zustand, der verhindert, dass zwei Setup-Versuche gleichzeitig ausgeführt werden.

## 4\. Überprüfung der Fertigstellung

Wenn der Status auf **Abgeschlossen**, prüfen Sie den resultierenden Pull Request in GitHub. Falls dies erneut fehlschlägt, verwenden Sie die neue Aktivität in der Karte anstelle des vorherigen Versuchs, um die nächste Aktion zu identifizieren.