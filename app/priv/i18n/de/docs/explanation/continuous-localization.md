%{
  title: "Kontinuierliche Lokalisierung",
  summary:
    "Machen Sie Sprachänderungen Teil des versionierten Lieferprozesses des Produkts, nicht eines separaten Export- und Import-Zyklus.",
  category: "Erklärung",
  section: "translation",
  order: 2
}
---

Kontinuierliche Bereitstellung funktioniert, weil kleine Änderungen eine wiederholbare Pipeline durchlaufen: Versionskontrolle, Überprüfung, Validierung und Deployment. Lokalisierung sollte in diese Pipeline passen, statt ein unbezogenes Referenzsystem einzuführen.

## Der getrennte Zyklus

In einem getrennten Workflow löst eine Produktänderung einen Export aus, die Bearbeitung erfolgt in einem anderen Tool, und der übersetzte Inhalt kehrt schließlich zurück. Zwischen diesen Schritten kann sich der Quelltext erneut ändern. Teams müssen Versionen bereinigen, entscheiden, ob Übersetzungen veraltet sind, und eine weitere Version koordinieren.

Das Problem ist nicht, dass ein Web-Editor inhärent falsch ist. Vielmehr kann ein unabhängig autoritatives Bearbeitungssystem sprachliche Entscheidungen vom Code und der Inhaltrevision trennen, die er beschreibt.

## Der Repository-Zyklus

Der Repository-Workflow von Glossia hält Quelldateien und Lokalisierungs-Konfiguration in Git. Ein verbundenes Repository liefert den Inhalt und Zielsprachen. Übersetzungsänderungen kehren als überprüfbare Repository-Änderungen zurück, sodass Teams ihre bestehenden Pull-Request- und Veröffentlichungs-Konventionen anwenden können.

Ein typischer Zyklus ist:

1. Ein Team ändert den Quellinhalt mit dem Produkt.
2. Glossia identifiziert Inhalte, die eine Übersetzung oder Verfeinerung benötigen.
3. Sprachanleitung und Terminologie bieten Kontext für die Transformation.
4. Validierung prüft das Ergebnis und Fehler bleiben handhabbar.
5. Rezensenten prüfen die Änderungen, bevor die Veröffentlichungs-Pipeline sie bereitstellt.

[Progressive Verfeinerung](./progressive-refinement) erklärt, wie Hashing und Validierung in diesen Zyklus passen. [Übersetzungswiederherstellung](./translation-recovery) erklärt, was passiert, wenn die Generierung oder Validierung fehlschlägt.

## Kontinuierlich bedeutet nicht ungeprüft

Eine kontinuierlich auslieferbare Änderung ist nicht notwendigerweise eine automatisch genehmigte Änderung. Rechtssprache, Produktversprechen und kultursensible Materialien benötigen möglicherweise eine Expertenprüfung. Das Beibehalten dieser Prüfung im Auslieferungszyklus ermöglicht einem Team, das geeignete Gate zu wählen, ohne eine separate Publikationsautorität unterhalten zu müssen.

Ebenso bedeutet kontinuierliche Lokalisierung nicht, das gesamte Repository bei jedem Commit zu übersetzen. Unveränderter Inhalt sollte dieselben Ressourcen nicht wiederholt verConsumen.

## Die praktische Grenze

Glossia liefert Sprachkontext und Lokalisierungsmechanismen. Die Prüfungen und der Bereitstellungsprozess Ihres Repositories bestimmen weiterhin, wann eine Änderung sicher veröffentlicht werden kann. Glossia ist kein Ersatz für Anwendungstests oder die Verantwortung eines Editors für Genauigkeit.

Andere Plattformen bieten ebenfalls Git-Integrationen und CI-Automatisierung an. Der Unterschied liegt im beabsichtigten Schwergewicht: Glossia ist um den Inhaltserweiterung und -prüfung im Repository aufgebaut, nicht um die Anforderung, die laufende redaktionelle Autorität in einen gehosteten Übersetzungs-Arbeitsbereich zu verlagern.
