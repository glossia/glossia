%{
  title: "Warum Glossia",
  summary:
    "Eine Sprach-OS, die Inhalt, Kontext und Review mit Continuous Delivery in Einklang hält.",
  category: "Erklärung",
  section: "translation",
  order: 1
}
---

Ein Produkt kann kontinuierlich ausgeliefert werden, während seine Übersetzungen sich in einem separaten Veröffentlichungszyklus feststecken. Änderungen am Quellinhalt finden in Git statt, jemand exportiert es in ein Translationssystem, Bearbeiter arbeiten dort und jemand importiert das Ergebnis. Das Produkt und seine Sprachversionen driften auseinander.

Glossia ist eine Sprach-OS, die auf einer anderen Prämise basiert: Spracharbeit sollte den gleichen versionierten, überprüfbaren Lieferzyklus wie das Produkt selbst durchlaufen.

## Das Problem ist größer als die Übersetzung

Teams müssen Bedeutung bewahren, Termini anwenden, die Tonalität des Publikums treffen und Inhalte aktualisieren, während das Produkt sich entwickelt. Diese Entscheidungen betreffen Dokumentation, UI-Strings, Marketingseiten und agentengenerierte Texte gleichermaßen.

Ein Modell kann einen nützlichen Entwurf erstellen. Es weiß an sich nicht, die Sprachentscheidungen Ihrer Organisation, die Gründe für Änderungen an Phrasen, die Validierung Ihrer Dateiformate oder die Synchronisation der nächsten Quellrevision zu erfassen. Die Wiederholung eines Prompts ist kein Liefersystem.

Glossia kombiniert den Sprachkontext mit den Mechanismen rund um die Generierung: Konfiguration, Änderungserkennung, Validierung, Fehlerwiederherstellung, Versionshistorie und Überarbeitung.

## Inhalte bleiben beim Produkt

Das Repository bleibt die Autorität für veröffentlichten Inhalt. Quelldateien, Konfiguration, generierte Übersetzungen und überprüfbare Änderungen können durch Git und Pull-Requests reisen. Teams müssen keine gehostete Bearbeitungschnittstelle für jeden Satz als Autorität wählen, bevor sie eine lokalisierte Version bereitstellen können.

Dies macht Sprachänderungen sichtbar neben der Produktänderung, die sie motivierte. Ein Rezensent kann den Diff untersuchen, CI kann die Ausgabe validieren und die gleiche Lieferpipeline kann sie veröffentlichen.

Lesen Sie [Kontinuierliche Lokalisierung](./continuous-localization) für das Liefermodell und [Inhaltsbesitz](./content-ownership) für seine Implikationen hinsichtlich der Portabilität.

## Kontext ist eine Eingabe, kein Käfig

Stimmführung und Terminologie unterstützen Menschen und Agenten dabei, konsistent zu schreiben. Sie sind wiederverwendbare Sprachentscheidungen, nicht nur eine proprietäre Sammlung von Quote-Ziel-Segmentpaaren.

Übersetzungsspeicher bleiben nützlich für etablierte Übersetzungen und wiederkehrende Inhalte. Es geht nicht darum, sie wegzuschmeißen. Es geht darum, sicherzustellen, dass kein Speicherformat oder Arbeitsablauf eines Anbieters der einzige Ort ist, an dem das Sprachwissen eines Unternehmens leben kann.

## Verbesserung ist ein Kreislauf

Das progressive-Verfeinerungsmodell von Glossia nutzt Inhalts-Hashes, um redundante Arbeit zu vermeiden, führt Validierung um Transformationen herum und macht Fehler sichtbar, sodass ein Lauf sich erholen kann. Menschliche Korrekturen können die nächste Iteration informieren, statt in eine isolierte Generierung zu verschwinden.

Lokalisierungsanalysen liefern eine weitere Eingabe: Das Verständnis der Sprachen und Orte, die ein Publikum nutzt, kann einem Team helfen, zu entscheiden, wo zu investieren. Es ist ein Fundament für Priorisierung, kein Versprechen, dass eine Übersetzung Wachstum produzieren wird.

## Für wen es passt

Glossia ist besonders relevant, wenn Entwickler, Linguisten und Produktteams an Repository-gesteuerten Inhalten zusammenarbeiten und diese kontinuierlich veröffentlichen möchten. Es ist keine Aussage, dass jede Organisation ihren bestehenden TMS aufgeben sollte. Ein Team, dessen zentrales Erfordernis ist ein reifer, browserbasierter Editor, die Koordination einer Übersetzungsagentur oder ein großer, etablierter Speicher, kann einen anderen Workflow bevorzugen.

## Überprüfbare Implementierung

Der Code von Glossia ist öffentlich verfügbar, einschließlich seiner Phoenix-Anwendung, seiner Rust-CLI, des Web-SDKs und der Bereitstellungsinfrastruktur. Damit sind die Mechanismen der Spracharbeit überprüfbar und nicht eine Blackbox.

Das Repository verwendet derzeit die [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md), die Nutzung und Modifikation erlaubt, aber konkurrierende gehostete Dienste einschränkt. Die öffentliche Quellverfügbarkeit und Lizenzfreiheiten sind unterschiedlich; lesen Sie die Lizenz, bevor Sie einen Dienst verteilen oder betreiben.
