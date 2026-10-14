%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, nachdem die Einrichtung einen Fehler meldet.",
  category: "Anleitung",
  section: "translation",
  order: 4
}
---

Wenn das automatisierte Setup fehlschlägt, verwirft Glossia das vorläufige Projekt, damit das Repository erneut ausgewählt werden kann. Eine Fehlermeldung kann im Setup-Verlauf angezeigt werden, aber das fehlgeschlagene Projekt und dessen Verlauf werden nicht gespeichert.

## 1. Den Fehler lesen

Lesen Sie den Fehlerhinweis, bevor Sie den Setup-Verlauf verlassen. Zu den gängigen Ursachen gehören:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Anbieterschlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann nicht auf das Repository zugreifen.
- Das Repository konnte nicht vorbereitet oder geprüft werden.

## 2. Die Voraussetzung beheben

Bei Modellproblemen öffnen Sie **Einstellungen → Modelle**. Bei Problemen mit dem Repository-Zugriff aktualisieren Sie die Installation der Glossia GitHub App in GitHub und gewähren ihr Zugriff auf das Repository.

## 3. Setup erneut starten

Öffnen Sie **Projekte → Neues Projekt**, wählen Sie das Repository aus, wählen Sie **Automatisiertes Setup** und wählen Sie die Zielsprachen erneut aus. Folgen Sie dem neuen Setup-Versuch, bis er abgeschlossen ist.

Wenn ein fehlgeschlagenes Projekt noch sichtbar ist und **Setup wiederholen** anbietet, startet diese Aktion einen weiteren Versuch. Verlassen Sie sich nicht darauf, dass sie verfügbar bleibt: fehlgeschlagene vorläufige Projekte werden während der Bereinigung entfernt.

## 4. Abschluss überprüfen

Wenn das Setup abgeschlossen ist, prüfen Sie den resultierenden Pull-Request in GitHub. Weitere Informationen zum Lebenszyklus und zur Bereinigung finden Sie unter [Projektsetup](/docs/reference/project-setup).
