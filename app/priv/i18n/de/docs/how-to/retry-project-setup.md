%{
  title: "Projekt einrichten wiederholen",
  summary: "Projekt nach fehlgeschlagener Einrichtung wiederherstellen.",
  category: "Anleitung",
  order: 4
}
---
Verwenden Sie **Wiederherstellen des Setups** nach Behebung des Fehlers, der einen Projektaufbau verhindern hat.

## Lesen Sie den Fehler

Öffnen Sie die Projektübersicht. Die Karte des Durchführungsfortschritts zeigt den Fehler und die neueste Aktivität der Einrichtung.

Häufige Ursachen sind:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Provider-Key fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann das Repository nicht erreichen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## Beheben Sie die Voraussetzung

Für Modellprobleme öffnen Sie **Einstellungen** und **Modelle**. Bei Repository-Zugangsproblemen aktualisieren Sie die Glossia GitHub App-Installation in GitHub und gewähren Sie ihr den Zugriff auf das Repository.

## Wiederholen

Kehren Sie zur Projektübersicht zurück und wählen **Wiederherstellen des Setups**.

Die Karte kehrt zu **In Wartestellung**, dann **Läuft**, und zeigt neue Aktivitäten, während die Arbeit fortschreitet. Wiederholen ist nur verfügbar, solange sich das Projekt im **Gescheitert** Zustand befindet, was verhindert, dass zwei Einrichtungsvorgänge gleichzeitig ausgeführt werden.

## Überprüfung der Vervollständigung

Wenn sich der Zustand in **Vollendet** ändert, überprüfen Sie den daraus resultierenden Pull Request in GitHub. Wenn dieser erneut fehlschlägt, verwenden Sie die neue Aktivität in der Karte anstelle des vorherigen Versuchs, um die nächste Aktion zu identifizieren.