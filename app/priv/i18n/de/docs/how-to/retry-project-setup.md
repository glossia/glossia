%{
  title: "Projekt-Setup erneut ausführen",
  summary: "Projekt wiederherstellen, falls das Setup einen Fehler meldet.",
  category: "Anleitung",
  section: "translation",
  order: 4
}
---

Wenn die automatisierte Einrichtung fehlschlägt, verwirft Glossia das vorläufige Projekt, damit das Repository erneut ausgewählt werden kann. Ein Fehlerhinweis kann im Einrichtungsablauf erscheinen, aber das fehlgeschlagene Projekt und sein Fortschrittsverlauf werden nicht gespeichert.

## 1. Lesen Sie den Fehler

Lesen Sie den Fehlerhinweis, bevor Sie den Einrichtungsablauf verlassen. Häufige Ursachen sind:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub-App kann nicht auf das Repository zugreifen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## 2. Beheben Sie die Voraussetzung.

Bei Problemen mit dem Modell, öffnen Sie **Einstellungen → Modelle**. Bei Problemen mit dem Repository-Zugriff aktualisieren Sie die Glossia GitHub-App-Installation in GitHub und gewähren Sie ihr Zugriff auf das Repository.

## 3. Starten Sie die Einrichtung erneut

Öffnen Sie **Projekte → Neues Projekt**, wählen Sie das Repository aus, wählen Sie **Automatische Einrichtung** und wählen Sie die Zielsprachen erneut aus. Verfolgen Sie den neuen Einrichtungsvorgang, bis er abgeschlossen ist.

Wenn ein fehlgeschlagenes Projekt noch sichtbar ist und **Einrichtung erneut versuchen** anbietet, startet diese Aktion einen weiteren Versuch. Verlassen Sie sich nicht darauf, dass dieses weiterhin verfügbar ist: Fehlgeschlagene vorläufige Projekte werden während der Bereinigung entfernt.

## 4. Abschluss überprüfen

Wenn die Einrichtung abgeschlossen ist, überprüfen Sie den resultierenden Pull Request in GitHub. Sehen Sie [Projekteinrichtung](/docs/reference/project-setup) für den Lebenszyklus und das Bereinigungsverhalten nach.
