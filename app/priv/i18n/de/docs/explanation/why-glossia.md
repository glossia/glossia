%{
  title: "Warum Glossia",
  summary:
    "Ein Sprach-OS, das Inhalte, Kontext und Reviews im Einklang mit Continuous Delivery hält.",
  category: "Erklärung",
  section: "translation",
  order: 1
}
---

Ein Produkt kann kontinuierlich ausgeliefert werden, während seine Übersetzungen in einem separaten Release-Zyklus hängen bleiben. Quelldateiänderungen in Git, jemand exportiert sie in ein Übersetzungssystem, Bearbeitende arbeiten dort, und jemand importiert das Ergebnis. Das Produkt und seine Sprachversionen driften auseinander.

Glossia ist ein Sprach-OS, das auf einem anderen Prinzip basiert: Spracharbeit sollte demselben versionierten, überprüfbaren Bereitstellungszyklus wie das Produkt selbst folgt.

## Das Problem ist umfangreicher als die Übersetzung

Teams müssen Bedeutung bewahren, Terminologie anwenden, den Tonfall der Zielgruppe treffen und Inhalt aktualisieren, während sich das Produkt entwickelt. Diese Entscheidungen wirken sich auf Dokumentation, UI-Strings, Marketingseiten und KI-generierte Texte gleichermaßen aus.

Ein Modell kann einen nützlichen Entwurf produzieren. Es kennt jedoch von sich aus nicht die Sprachentscheidungen Ihrer Organisation, zeichnet nicht auf, warum sich ein Ausdruck geändert hat, validiert nicht Ihre Dateiformate oder synchronisiert nicht die nächste Quellrevision. Das Wiederholen eines Prompts ist kein Verteilungssystem.

Glossia kombiniert Sprach-Kontext mit den Mechanismen um die Generierung: Konfiguration, Änderungserkennung, Validierung, Fehlerwiederherstellung, Revisionshistorie und Überprüfung.

## Inhalte bleiben beim Produkt

Das Repository bleibt die Autorität für veröffentlichten Inhalt. Quelldateien, Konfiguration, generierte Übersetzungen und überprüfbare Änderungen können durch Git und Pull-Requests durchgehen. Teams müssen eine gehostete Bearbeitungs-Schnittstelle nicht zur Autorität für jeden Satz machen, bevor sie eine lokalisierte Version liefern können.

Dies macht Sprachänderungen sichtbar neben der Produktänderung, die sie motiviert. Ein Prüfer kann den Diff inspizieren, CI kann die Ausgabe validieren und die gleiche Bereitstellungs-Pipeline kann sie veröffentlichen.

Lesen Sie [Kontinuierliche Lokalisierung](./continuous-localization) für das Bereitstellungsmodell und [Inhaltsbesitz](./content-ownership) für die Auswirkungen auf die Portierbarkeit.

## Kontext ist eine Eingabe, keine Fessel

Stimmen-Anweisungen und Terminologie helfen sowohl Menschen als auch Agenten beim konsistenten Schreiben. Es handelt sich um wiederverwendbare Sprachentscheidungen, nicht um eine proprietäre Sammlung von Quell-Ziel-Segmentpaaren.

Übersetzungsgedächtnisse bleiben für etablierte Übersetzungen und wiederholenden Inhalt nützlich. Der Punkt ist nicht, sie zu verwerfen. Der Punkt ist, zu vermeiden, dass das Gedächtnisformat oder der Bearbeitungsablauf eines Anbieters der einzige Ort ist, an dem das Sprachwissen eines Unternehmens leben kann.

## Verbesserung ist ein Kreislauf

Das allmähliche Verfeinerungsmodell von Glossia verwendet Inhalts-Hashes, um redundante Arbeit zu vermeiden, führt Validierung um Transformationen herum durch und legt Fehler offen, sodass eine Ausführung wiederhergestellt werden kann. Menschliche Korrekturen können die nächste Iteration informieren, statt in einer isolierten Generierung zu verschwinden.

Lokalisierungs-Analytik bietet eine weitere Eingabe: die Kenntnis der Sprachen und Orte, die eine Zielgruppe nutzt, kann einem Team helfen, zu entscheiden, wo zu investieren. Es ist Beweismaterial für Priorisierung, keine Zusage, dass eine Übersetzung Wachstum produzieren wird.

## Für wen es passt

Glossia ist besonders relevant, wenn sich Entwickler, Linguisten und Produktteams an repository-gestartetem Inhalt wohlfühlen und ihn kontinuierlich veröffentlichen wollen. Es ist keine Behauptung, dass jede Organisation ihren bestehenden TMS aufgeben sollte. Ein Team, dessen zentrale Anforderung ein reifer browserbasierter Editor, die Koordinierung mit Übersetzungsagenturen oder ein großes etabliertes Gedächtnis ist, mag einen anderen Workflow bevorzugen.

## Überprüfbare Implementierung

Der Code von Glossia ist öffentlich verfügbar, einschließlich seiner Phoenix-Anwendung, seiner Rust-CLI, seines Web-SDK und seiner Bereitstellungsinfrastruktur. Das macht die Mechanismen der Spracharbeit überprüfbar statt einer schwarzen Box.

Glossia folgt einem Open-Core-Modell. Der Kern verwendet [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), was kommerzielle Nutzung, Self-Hosting und konkurrierende gehostete Dienste erlaubt. Das `ee/` Verzeichnis hat eine separate [Unternehmenslizenz](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md), die eine schriftliche geschäftliche Vereinbarung für den Productionseinsatz erfordert. Lesen Sie die anwendbare Lizenz, bevor Sie Unternehmensfunktionen verteilen oder betreiben.
