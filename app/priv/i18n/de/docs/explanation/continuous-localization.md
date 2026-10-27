%{
  title: "Kontinuierliche Lokalisierung",
  summary:
    "Machen Sie sprachliche Änderungen Teil des versionsbasierten Lieferzyklus des Produkts, statt in einen separaten Export- und Import-Zyklus.",
  category: "Erklärung",
  section: "translation",
  order: 2
}
---

Kontinuierliefe funktioniert, weil kleine Änderungen durch eine wiederholbare Pipeline laufen: Versionskontrolle, Überprüfung, Validierung und Bereitstellung. Lokalisierung sollte in diese Pipeline passen, statt ein unabhängiges Referenzsystem einzuführen.

## Der getrennte Kreislauf

In einem getrennten Workflow löst eine Produktänderung einen Export aus, die Arbeit findet in einem anderen Tool statt, und der übersetzte Inhalt kehrt schließlich zurück. Zwischen den Schritten kann sich die Quelle erneut ändern. Teams müssen Versionen abstimmen, entscheiden, ob Übersetzungen veraltet sind, und eine weitere Veröffentlichung koordinieren.

Das Problem ist nicht, dass ein Web-Editor an sich falsch ist. Es ist, dass ein eigenständig autorisiertes Bearbeitungssystem Sprachentscheidungen vom Code und der Inhaltsrevision trennen kann, die es beschreibt.

## Der Repository-Kreislauf

Der Repository-Workflow von Glossia hält Quelldateien und Lokalisierungseinstellungen in Git. Ein verbundenes Repository liefert den Inhalt und die Zielsprachen. Übersetzungsänderungen kehren als überprüfbare Repository-Änderungen zurück, sodass Teams ihre bestehenden Pull-Request-und Veröffentlichungsvorgaben anwenden können.

Ein typischer Kreislauf ist:

1. Ein Team verändert den Quellinhalt im Produkt.
2. Glossia identifiziert Inhalt, der Übersetzung oder Verfeinerung bedarf.
3. Sprachliche Hinweise und Terminologie bieten Kontext für die Transformation.
4. Validierung prüft das Ergebnis und Fehler bleiben handhabbar.
5. Rezensenten prüfen die Änderungen, bevor die Publishing-Pipeline sie bereitstellt.

[Progressive Verfeinerung](./progressive-refinement) erklärt, wie Hashing und Validierung in diesen Kreislauf passen. [Übersetzungswiederherstellung](./translation-recovery) erklärt, was passiert, wenn Generierung oder Validierung fehlschlägt.

## Kontinuierliefe bedeutet nicht unüberprüft

Eine kontinuierliefe lieferbare Änderung ist nicht zwingend eine automatisch genehmigte Änderung. Juristische Sprache, Produktversprechen und kulturell sensible Materialien benötigen möglicherweise eine Expertenprüfung. Das Beibehalten dieser Überprüfung im Bereitstellungsprozess ermöglicht einem Team, die passende Hürde zu wählen, ohne eine separate Veröffentlichungsinstanz aufrechtzuerhalten.

Außerdem bedeutet kontinuierliefe Lokalisierung nicht, das gesamte Repository bei jedem Commit zu übersetzen. Ungeänderte Inhalte sollten nicht immer wieder dieselben Ressourcen verbrauchen.

## Die praktische Grenze

Glossia bietet Sprachkontext und Lokalisierungsmechanismen. Die Prüfungen und der Bereitstellungsprozess Ihres Repositories bestimmen weiter, wann eine Änderung sicher veröffentlicht werden kann. Glossia ist kein Ersatz für Anwendungstests oder die Verantwortung eines Editors für Richtigkeit.

Andere Plattformen bieten ebenfalls Git-Integrationen und CI-Automatisierung an. Der Unterschied liegt im geplanten Schwerpunkt: Glossia ist darauf ausgerichtet, Eigentum an Inhalten und deren Prüfung im Repository zu betreiben, nicht auf die Anforderung, anhaltende redaktionelle Autorität in einen gehosteten Übersetzungsarbeitsraum zu verlagern.
