%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, wenn die Einrichtung einen Fehler meldet.",
  category: "Anleitung",
  order: 4
}
---
Verwenden **Einrichtung erneut versuchen** nach Behebung der Ursache, die das Scheitern der Projekteinrichtung verursachte.

## 1\. Fehler lesen

Öffnen Sie die Projektübersicht. Die Karte zum Einrichtungsfortschritt zeigt den Fehler und die letzte Einrichtungsaktivität an.

Häufige Ursachen umfassen:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann auf das Repository nicht zugreifen.
- Das Repository konnte nicht vorbereitet oder geprüft werden.

## 2\. Voraussetzung beheben

Für Modellprobleme öffnen **Einstellungen** und **Modelle**. Bei Problemen mit dem Repository-Zugriff aktualisieren Sie die Glossia GitHub App-Installation in GitHub und gewähren Sie ihr Zugriff auf das Repository.

## 3\. Wiederholen

Zurück zur Projektübersicht und auswählen **Setup wiederholen**.

Die Karte kehrt zurück zu **Anstehend**, dann **Laufend**, und zeigt neue Aktivitäten an, während die Arbeit voranschreitet. Die Wiederholung ist nur verfügbar, solange das Projekt im **Fehlgeschlagen** Status, der das gleichzeitige Ausführen von zwei Setup-Versuchen verhindert.

## 4\. Abschlussprüfung

Wenn sich der Status zu **Abgeschlossen**, prüfen Sie den resultierenden Pull-Request auf GitHub. Wenn dieser erneut fehlschlägt, verwenden Sie die neue Aktivität in der Karte anstelle des vorherigen Versuchs, um die nächste Aktion zu ermitteln.