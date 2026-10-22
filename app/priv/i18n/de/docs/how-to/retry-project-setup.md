%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Projekt nach fehlgeschlagener Einrichtung wiederherstellen.",
  category: "Anleitung",
  section: "translation",
  order: 4
}
---

Wenn die automatisierte Einrichtung fehlschlägt, wirft Glossia das vorläufige Projekt weg, sodass das Repository erneut ausgewählt werden kann. Ein Fehlerhinweis kann im Einrichtungsprozess angezeigt werden, aber das fehlgeschlagene Projekt und sein Fortschrittsverlauf werden nicht beibehalten.

## 1. Den Fehler lesen

Lesen Sie den Fehlerhinweis, bevor Sie den Einrichtungsprozess verlassen. Zu den häufigen Ursachen gehören:

- Das Konto hat kein konfiguriertes Modell.
- Der Anbieter-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub-App kann auf das Repository nicht zugreifen.
- Das Repository konnte nicht vorbereitet oder geprüft werden.

## 2. Die Voraussetzung beheben

Für Probleme mit dem Modell öffnen Sie **Einstellungen → Modelle**. Bei Problemen mit dem Zugriff auf das Repository aktualisieren Sie die Glossia GitHub-App-Installation in GitHub und gewähren Sie ihr Zugriff auf das Repository.

## 3. Einrichtung erneut starten

Öffnen Sie **Projekte → Neues Projekt**, wählen Sie das Repository aus, wählen Sie **Automatisierte Einrichtung** und wählen Sie zudem erneut die Zielsprachen aus. Folgen Sie dem neuen Einrichtungsversuch, bis er abgeschlossen ist.

Wenn ein fehlgeschlagenes Projekt noch sichtbar ist und **Einrichtung erneut durchführen** anbietet, startet diese Aktion einen weiteren Versuchsstart. Verlassen Sie sich nicht darauf, dass er weiterhin verfügbar bleibt: Fehlgeschlagene vorläufige Projekte werden während der Bereinigung entfernt.

## 4. Abschluss überprüfen

Wenn die Einrichtung abgeschlossen ist, prüfen Sie den resultingen Pull-Request in GitHub. Siehe [Projekt einrichten](/docs/reference/project-setup) für den Lebenszyklus und das Bereinigungsverhalten.
