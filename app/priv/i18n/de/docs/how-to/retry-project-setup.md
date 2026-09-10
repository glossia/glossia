%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, nachdem die Einrichtung einen Fehler meldet.",
  category: "Anleitung",
  order: 4
}
---
Verwenden **Einrichtung wiederholen** nachdem Sie die Bedingung behoben haben, die zu einer fehlgeschlagenen Projekteinrichtung führte.

## 1\. Die Fehlermeldung lesen.

Öffnen Sie die Projektübersicht. Die Karte zum Einrichtungsfortschritt zeigt den Fehler und die neueste Aktivität der Einrichtung.

Häufige Ursachen sind:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann nicht auf das Repository zugreifen.
- Das Repository konnte nicht vorbereitet oder geprüft werden.

## 2\. Die Voraussetzung beheben

Bei Modellproblemen öffnen **Einstellungen** und **Modelle**. Für Probleme mit dem Repository-Zugriff aktualisieren Sie die Glossia GitHub App-Installation in GitHub und erteilen Sie ihr Zugriff auf das Repository.

## 3\. Neuversuchen

Zurück zur Projektübersicht und wählen **Setup neuversuchen**.

Die Karte kehrt zurück zu **Ausstehend**, dann **Laufend**​, und zeigt neue Actividades an, während die Arbeit fortschreitet. Ein neuer Versuch ist nur verfügbar, während das Projekt im **Fehlgeschlagen** Status, der verhindert, dass zwei Einrichtungsversuche gleichzeitig ausgeführt werden.

## 4\. Abschlussprüfung

Wenn der Status auf **Abgeschlossen**, überprüfen Sie den daraus resultierenden Pull-Request auf GitHub. Wenn dieser erneut fehlschägt, verwenden Sie die neue Aktivität in der Karte statt des vorherigen Versuchs, um die nächste Aktion zu identifizieren.