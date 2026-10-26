%{
  title: "Kontinuierliche Lokalisierung",
  summary:
    "Integrieren Sie Sprachänderungen in den versionierten Bereitstellungszyklus des Produkts, statt einen separaten Export- und Import-Zyklus zu nutzen.",
  category: "Erklärung",
  section: "translation",
  order: 2
}
---

Continuous Delivery funktioniert, weil kleine Änderungen durch eine wiederholbare Pipeline fließen: Versionskontrolle, Überprüfung, Validierung und Bereitstellung. Lokalisierung sollte zu dieser Pipeline passen, statt ein unabhängiges System der Aufzeichnung einzuführen.

## Der abgekoppelte Kreislauf

In einem abgekoppelten Workflow löst eine Produktänderung einen Export aus, die Arbeit findet in einem anderen Tool statt, und die übersetzten Inhalte kehren schließlich zurück. Zwischen diesen Schritten kann sich der Quelltext erneut ändern. Teams müssen Versionen aufeinander abstimmen, entscheiden, ob Übersetzungen veraltet sind, und eine weitere Freigabe koordinieren.

Das Problem ist nicht, dass ein Web-Editor von Grund auf falsch ist. Es ist vielmehr, dass ein unabhängig autoritatives Bearbeitungssystem Sprachentscheidungen von der Code- und Inhaltsrevision trennen kann, die sie beschreiben.

## Der Repository-Kreislauf

Der Repository-Workflow von Glossia bewahrt Quelldateien und Lokalisierungs-Konfiguration in Git. Ein verbundenes Repository liefert den Inhalt und Zielsprachen. Übersetzungsänderungen kehren als überprüfbare Repository-Änderungen zurück, sodass Teams ihre bestehenden Pull-Request- und Veröffentlichungskonventionen anwenden können.

Ein typischer Kreislauf ist:

1. Ein Team ändert den Inhalt der Quelle mit dem Produkt.
2. Glossia identifiziert Inhalte, die übersetzt oder verfeinert werden müssen.
3. Sprachrichtlinien und Terminologie liefern Kontext für die Transformation.
4. Validierung prüft das Ergebnis, und Fehler bleiben lösbar.
5. Rezensenten prüfen die Änderungen, bevor die Veröffentlichungspipeline sie überreicht.

[Schrittweise Verfeinerung](./progressive-refinement) erklärt, wie Hashing und Validierung in diesen Kreislauf passen. [Wiedergewinnung von Übersetzungen](./translation-recovery) erklärt, was passiert, wenn die Generierung oder Validierung fehlschlägt.

## Kontinuierlich heißt nicht unüberprüft

Eine dauerhaft bereitstellbare Änderung ist nicht zwingend selbst genehmigt. Rechtssprache, Produktversprechen und kultursensible Inhalte können einer Expertenprüfung bedürfen. Durch die Einbindung dieser Prüfung in den Bereitstellungszyklus kann ein Team die richtige Hürde wählen, ohne eine separate Veröffentlichungsautorität aufrechtzuerhalten.

Auch bedeutet kontinuierliche Lokalisierung nicht, das ganze Repository bei jedem Commit zu übersetzen. Unveränderter Inhalt sollte nicht dieselben Ressourcen wiederholt verbrauchen.

## Die praktische Grenze

Glossia stellt Sprachkontext und Lokalisierungsmechanismen zur Verfügung. Die Prüfungen und der Bereitstellungsprozess Ihres Repositories bestimmen weiterhin, wann eine Änderung sicher bereitgestellt werden kann. Glossia ist kein Ersatz für Anwendungstests oder die Verantwortung eines Editors für die Genauigkeit.

Andere Plattformen bieten zudem Git-Integrationen und CI-Automatisierung an. Der Unterschied liegt im geplanten Schwerpunkt: Glossia ist um Inhaltswirtschaft und Prüfung im Repository herum aufgebaut, nicht um die Anforderung, die laufende redaktionelle Autorität in eine gehostete Übersetzungsarbeitsumgebung zu verlagern.
