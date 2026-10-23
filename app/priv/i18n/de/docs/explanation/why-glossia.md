%{
  title: "Warum Glossia",
  summary:
    "Ein Sprach-OS, das Inhalt, Kontext und Überprüfung mit der kontinuierlichen Bereitstellung in Einklang hält.",
  category: "Erklärung",
  section: "translation",
  order: 1
}
---

Ein Produkt kann kontinuierlich ausgeliefert werden, während seine Übersetzungen in einem separaten Release-Zyklus stecken bleiben. Quelleninhalte ändern sich in Git, jemand exportiert sie in ein Translationssystem, Bearbeiter arbeiten dort und jemand importiert das Ergebnis. Das Produkt und seine Sprachversionen driften auseinander.

Glossia ist ein Sprach-Betriebssystem, das auf einer anderen Prämise beruht: Spracharbeit sollte denselben versionierten, überprüfbaren Auslieferungszyklus wie das Produkt selbst folgen.

## Das Problem ist größer als die Übersetzung

Teams müssen Bedeutung bewahren, Terminologie anwenden, den Ton der Zielgruppe treffen und Inhalte aktualisieren, während sich das Produkt entwickelt. Diese Entscheidungen wirken sich auf Dokumentation, UI-Strings, Marketingseiten und durch Agenten generierten Texte gleichermaßen aus.

Ein Modell kann einen nützlichen Entwurf produzieren. Doch es kann allein nicht Ihre Sprachentscheidungen kennen, festhalten, warum sich ein Ausdruck geändert hat, Ihre Dateiformate validieren oder die nächste Quellrevision synchronisieren. Das Wiederholen eines Prompts ist kein Auslieferungssystem.

Glossia kombiniert Sprachkontext mit den Mechanismen der Generierung: Konfiguration, Änderungserkennung, Validierung, Fehlerwiederherstellung, Versionshistorie und Überprüfung.

## Inhalte bleiben beim Produkt

Das Repositorium bleibt die Autorität für veröffentlichte Inhalte. Quelldateien, Konfiguration, generierte Übersetzungen und überprüfbare Änderungen können durch Git und Pull-Requests reisen. Teams müssen keine gehostete Bearbeitungsui zur Autorität für jeden Satz machen, bevor sie eine lokalisierte Auslieferung bereitstellen können.

Dadurch werden Sprachänderungen zusammen mit der Produkänderung, die sie motivierte, sichtbar. Ein Rezensent kann den Diff prüfen, CI kann die Ausgabe validieren und die gleiche Auslieferungsleitung kann sie veröffentlichen.

Sehen Sie [Kontinuierliche Lokalisierung](./continuous-localization) für das Auslieferungsmodell und [Inhaltsbesitz](./content-ownership) für seine Portabilitätsaspekte.

## Kontext ist eine Eingabe, kein Käfig

Stimme-Richtlinien und Terminologie helfen sowohl Menschen als auch Agenten, konsistent zu schreiben. Sie sind wieder verwendbare Sprachentscheidungen, nicht nur eine proprietäre Sammlung von Quell-Ziel-Abschnitt-Paaren.

Übersetzungsspeicher bleiben für etablierte Übersetzungen und wiederkehrenden Inhalt nützlich. Es geht nicht darum, sie wegzuwerfen. Es geht darum, eines beliebigen Herstellers Speicherformat oder Bearbeitungsablauf als einzigen Ort zu vermeiden, an dem Sprachwissen eines Unternehmens leben kann.

Siehe [Sprachspeicher und Translationsspeicher](./language-memory-and-translation-memory).

## Verbesserung ist ein Zyklus

Das schrittweise-Verfeinerungs-Modell von Glossia verwendet Inhalts-Hashes, um überflüssige Arbeit zu vermeiden, führt Validierung um Transformationen herum durch und offenbart Fehler, damit ein Lauf von selbst wiederhergestellt werden kann. Menschliche Korrekturen können die nächste Iteration informieren, statt in eine isolierte Generierung zu verschwinden.

Lokalisierungsanalytik liefert eine weitere Eingabe: das Verstehen der Sprachen und Orte, die eine Zielgruppe nutzt, kann einem Team helfen, entscheiden, wo zu investieren. Es ist Beweismaterial für Priorisierung, keine Garantie, dass eine Übersetzung Wachstum produzieren wird.

## Für wen passt das

Glossia ist besonders relevant, wenn Entwickler, Linguisten und Produktteams Lust auf Zusammenarbeit an repository-verwalteten Inhalten haben und es kontinuierlich verfügbar machen. Es ist nicht eine Behauptung, dass jede Organisation ihren bestehenden TMS zugunsten verschrotten sollte. Ein Team, dessen zentrales Erfordernis ein ausgereifter browserbasierter Editor, Übersetzungs-Agentur-Koordination oder ein großer etablierter Speicher sein muss, kann einen anderen Workflow bevorzugen.

Die [Crowdin](./glossia-vs-crowdin), [Lokalise](./glossia-vs-lokalise), [Phrase](./glossia-vs-phrase) und [Weblate](./glossia-vs-weblate)-Vergleiche erklären diese Abwägungen.

## Überprüfbare Implementierung

Der Code von Glossia ist öffentlich verfügbar, einschließlich der Phoenix-Anwendung, Rust-CLI, Web-SDK und Deploy-Infrastruktur. Dadurch werden die Mechanismen der Spracharbeit überprüfbar und nicht als Blackbox.

Das Repositorium verwendet derzeit die [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md), die Nutzung und Modifikation erlaubt, aber konkurrierende gehostete Dienste einschränkt. Die öffentliche Quellverfügbarkeit und Lizenzfreiheiten sind unterschiedlich; lesen Sie die Lizenz, bevor Sie ein Dienst verteilen oder betreiben.
