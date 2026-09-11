%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, wenn die Projekt-Einrichtung einen Fehler meldet.",
  category: "Anleitung",
  order: 4
}
---
Verwenden **Einrichtung erneut versuchen** nachdem Sie die Bedingung behoben haben, die zum Scheitern der Projekteinrichtung geführt hat.

## 1\. Fehlermeldung lesen

Öffnen Sie die Projektübersicht. Die Karte des Einrichtungsfortschritts zeigt den Fehler und die neueste Einrichtungstätigkeit.

Häufige Ursachen sind:

- Das Konto hat kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann auf das Repository nicht zugreifen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## 2\. Voraussetzung beheben

Für Modellprobleme öffnen **Einstellungen** und **Modelle**. Bei Zugriffsproblemen auf das Repository aktualisieren Sie die Glossia GitHub App-Installation in GitHub und gewähren Sie ihr Zugriff auf das Repository.

## 3\. Wiederholen

Zurück zur Projektübersicht gehen und auswählen **Setup wiederholen**.

Die Karte kehrt zu **Ausstehend**, dann **Läuft**, und zeigt neue Aktivitäten, wenn Arbeit erledigt wird. Der Neustart ist nur möglich, solange das Projekt im **Fehlgeschlagen** Zustand, der zwei gleichzeitige Einrichtungsvorgänge verhindert.

## 4\. Abschlussprüfung

Wenn der Status zu **Abgeschlossen**, prüfen Sie die resultierende Pull Request auf GitHub. Wenn es erneut fehlschlägt, nutzen Sie die neuen Aktivitäten in der Karte statt des vorherigen Versuchs, um die nächste Aktion zu identifizieren.