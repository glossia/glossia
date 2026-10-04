%{
  title: "Projekt-Einrichtung erneut versuchen",
  summary: "Ein Projekt wiederherstellen, wenn die Einrichtung einen Fehler meldet.",
  category: "Anleitung",
  section: "translation",
  order: 4
}
---
Wenn die automatisierte Einrichtung fehlschlägt, verwirft Glossia das vorläufige Projekt, damit das Repository erneut ausgewählt werden kann. Eine Fehlermeldung kann im Einrichtungsablauf erscheinen, aber das fehlgeschlagene Projekt und sein Fortschrittsverlauf werden nicht gespeichert.

## 1\. Die Fehlermeldung lesen

Lesen Sie die Fehlermeldung vor dem Verlassen des Einrichtungsablaufs. Häufige Ursachen sind:

- Das Konto verfügt über kein konfiguriertes Modell.
- Der Provider-Schlüssel fehlt oder ist nicht mehr gültig.
- Die Glossia GitHub App kann auf das Repository nicht zugreifen.
- Das Repository konnte nicht vorbereitet oder überprüft werden.

## 2\. Die Voraussetzung beheben

Für Modellprobleme, öffnen **Einstellungen → Modelle**. Bei Zugriffsproblemen zur Repositories aktualisieren Sie die Glossia GitHub App-Installation auf GitHub und gewähren Sie dieser Zugriff auf die Repositories.

## 3\. Starten Sie die Einrichtung neu

Öffnen **Projekte → Neues Projekt**, wählen Sie die Repositories aus und wählen **Automatisierte Einrichtung**und wähle die Zielsprachen erneut aus. Folge dem neuen Setupsversuch, bis er abgeschlossen ist.

Wenn ein fehlgeschlagenes Projekt weiterhin sichtbar ist und anbietet **Neustart der Einrichtung**, leitet diese Aktion einen weiteren Versuch ein. Verlassen Sie sich nicht darauf, dass er weiterhin verfügbar bleibt: fehlgeschlagene temporäre Projekte werden während der Bereinigung entfernt.

## 4\. Abschlussprüfung

Wenn die Einrichtung abgeschlossen ist, prüfe den resultierenden Merge-Request in GitHub. Siehe [Projekteinrichtung](/docs/reference/project-setup) zur Lebenszyklus- und Bereinigungsverarbeitung.