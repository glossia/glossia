%{
  title: "Kontinuierliche Lokalisierung",
  summary:
    "Machen Sie Sprachänderungen Teil des produktversionierten Lieferzyklus des Produkts, nicht eines separaten Export- und Import-Zyklus.",
  category: "Erklärung",
  section: "translation",
  order: 2
}
---

Kontinuierliche Auslieferung funktioniert, weil sich kleine Änderungen durch eine wiederholbare Pipeline bewegen: Versionskontrolle, Überprüfung, Validierung und Bereitstellung. Lokalisierung sollte diese Pipeline ergänzen, statt ein unabhängiges Aufzeichnungssystem einzuführen.

## Der getrennte Kreislauf

In einem abgekoppelten Workflow löst eine Produktänderung einen Export aus, die Bearbeitung findet in einem anderen Tool statt und der übersetzte Inhalt kehrt schließlich zurück. Zwischen den Schritten kann sich die Quelle erneut ändern. Teams müssen Versionen vereinheitlichen, entscheiden, ob Übersetzungen veraltet sind, und eine weitere Freigabe koordinieren.

Das Problem ist nicht, dass ein Web-Editor per se falsch wäre. Vielmehr kann ein eigenständig autoritatives Bearbeitungssystem Sprachentscheidungen vom Code und den Inhalten trennen, die es beschreibt.

## Der Repository-Kreislauf

Glossias Repository-Workflow hält Quelldateien und Lokalisierungskonfigurationen in Git. Ein verbundenes Repository liefert den Inhalt und die Zielsprachen. Übersetzungsänderungen kommen als überprüfbare Repository-Änderungen zurück, sodass Teams ihre bestehenden Pull-Request und Veröffentlichungsmuster anwenden können.

Ein typischer Kreislauf sieht wie folgt aus:

1. Ein Team ändert den Quelldaten mit dem Produkt.
2. Glossia identifiziert Inhalt, der übersetzt oder verfeinert werden muss.
3. Sprachanweisungen und Termini bieten Kontext für die Transformation.
4. Die Validierung prüft das Ergebnis und Fehler bleiben handhabbar.
5. Prüfer inspizieren die Änderungen, bevor die Publikationspipeline sie bereitstellt.

[Progressive Verfeinerung](./progressive-refinement) erklärt, wie Hashing und Validierung in diesen Kreislauf passen. [Übersetzungswiederherstellung](./translation-recovery) erklärt, was passiert, wenn Generierung oder Validierung fehlschlägt.

## Kontinuierlich bedeutet nicht unbeaufsichtigt

Eine kontinuierlich auslieferbare Änderung ist nicht automatisch ein genehmigter Änderung. Juristischer Inhalt, Produktversprechen und kulturell sensibles Material können eine Fachexpertiseprüfung erfordern. Die Einbindung dieser Prüfung in den Auslieferungszweielf lässt dem Team die Wahl des entsprechenden Gating-Zeugs, ohne eine separate Publikationsauftragsstruktur aufrechterhalten zu müssen.

Kontinuierliche Lokalisierung bedeutet auch nicht, das gesamte Repository bei jedem Commit zu übersetzen. Unveränderter Inhalt sollte nicht wiederholt dieselben Ressourcen verbrauchen.

## Die praktische Grenze

Glossia stellt Sprachkontext und Lokalisierungsmechaniken bereit. Die Prüfungen und Bereitstellungsprozesse Ihres Repository definieren weiterhin, wann eine Änderung sicher publiziert werden kann. Glossia ist keine Alternative zu Anwendungstests oder zur Verantwortung eines Editors für Richtigkeit.

Andere Plattformen bieten ebenfalls Git-Integrationen und CI-Automatisierung. Der Unterschied liegt im intendierten Schwerpunkt: Glossia ist um Inhaltsbesitz und Prüfung im Repository herum aufgebaut, nicht um eine Anforderung, die laufende redaktionelle Autorität in einen gehosteten Übersetzungsarbeitsbereich zu verlagern.
