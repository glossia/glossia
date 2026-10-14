%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und bereiten Sie dessen erste Lokalisierungseinrichtung vor.",
  category: "Anleitungen",
  order: 1
}
---

Dieses Tutorial verbindet ein GitHub-Repository mit Glossia, wählt die ersten Ziel-Sprachen und bereitet eine Übersetzungs-Basis für Ihr Team zur Überprüfung vor.

## Bevor Sie beginnen

Benötigt:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, das Sie der Glossia-GitHub-App zur Lese- und Schreibzugriffserteilung gestatten können.
- Ein Provider-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1. Konfigurieren Sie ein Kontomodell

Öffnen Sie **Einstellungen**, wechseln Sie dann zu **Modell** und wählen Sie **Neues Modell**.

1. Geben Sie dem Modell einen kurzen Handle, wie `translation-default`.
2. Öffnen Sie den Modell-Auswahlbereich und geben Sie Teil eines Anbieter- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell, das Glossia verwenden soll.
4. Geben Sie den Provider-Schlüssel ein und speichern Sie das Modell.

Der Handle ermöglicht es Repositories, sich auf dieses Kontomodell zu beziehen, ohne Anbieter-Credentials in der Versionskontrolle zu platzieren. Siehe [Konfigurieren eines Modell-Anbieters](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2. Starten Sie ein Projekt

Gehen Sie zurück zu **Projekte** und wählen Sie **Neues Projekt**.

Wenn Glossia nach Repository-Zugriff fragt, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia-GitHub-App den Zugang zum Repository. Nach der Rückkehr zu Glossia öffnen Sie ggf. **Neues Projekt**.

## 3. Wählen Sie ein Repository

Wählen Sie das Repository, das Sie lokalisieren möchten. Glossia führt lediglich Repositories auf, die über die GitHub-App-Installation des aktuellen Kontos verfügbar sind.

## 4. Wählen Sie eine Projekt-Einrichtungsmethode

Wählen Sie **Automatisierte Einrichtung**, um Glossia zuzulassen, das Repository zu prüfen und die Lokalisierungs-Konfiguration in einem Pull-Request vorzuschlagen. Dieses Tutorial folgt diesem Pfad.

Wenn das Repository bereits eine `L10N.md`-Datei enthält, oder Sie würden es lieber selbst schreiben, wählen Sie stattdessen **Manuelle Konfiguration**. Glossia erstellt das Projekt sofort und Sie können die übbrigen Schritte überspringen. Siehe [Projekt-Einrichtung](/docs/reference/project-setup) für den Zweck jedes Modus.

## 5. Wählen Sie Ziel-Sprachen

Wählen Sie eine oder mehr Sprachen, aus denen aus dem Quellinhalt des Repositoriums produziert werden soll, und starten Sie die Einrichtung.

## 6. Verfolgen Sie den Einrichtungsfortschritt

Halten Sie die Einrichtungsseite offen, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die häufigste Aktivität, einschließlich Repositories-Vorbereitung, Dateiprüfung, Änderungen, Prüfungen und Abschluss.

Sie können die Seite verlassen und zur Projekt-Übersicht zurückkehren, ohne den Einrichtungsstatus zu verlieren. Wenn die Einrichtung fehlschlägt, lesen Sie die Fehlermitteilung. Glossia wirft das vorläufige Projekt weg; beheben Sie die Voraussetzung und beginnen Sie erneut über **Neues Projekt**. Siehe [Projekt-Einrichtung erneut versuchen](/docs/how-to/retry-project-setup).

## 7. Überprüfen Sie das Ergebnis

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projekt-Übersicht und überprüfen Sie den für das Repository erstellten Pull-Request. Die vorgeschlagene Basis umfasst normalerweise:

- Eine Root-`L10N.md`-Datei mit Ursprungssprache, Ursprungspfaden und Ziel-Sprachen.
- Die kleinsten Anwendungs- oder Inhaltsänderungen, die zum Laden lokalisierter Dateien notwendig sind.
- Jede leichte Validierung, die bereits im Repository verfügbar war.

Überprüfen und verbinden Sie den Pull-Request über Ihren normalen GitHub-Workflow. Zukünftige Übersetzungsabläufe nutzen den zusammengeführten `L10N.md`-Kontext.

Die Projekt-Übersicht hält den Einrichtungs-Pull-Request visuell bis zum Zusammenführen. Wenn er geschlossen wurde, ohne zusammengeführt zu werden, öffnen Sie ihn über den Link in der Einrichtungsmitteilung.

## Nächste Schritte

- [Neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projekt-Einrichtungs-Status verstehen](/docs/reference/project-setup)
- [Erfahren Sie, wie Kontomodellen funktionieren](/docs/explanation/account-models)
