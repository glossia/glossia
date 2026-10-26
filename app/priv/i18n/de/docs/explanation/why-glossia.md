%{
  title: "Warum Glossia",
  summary:
    "Ein Sprach-Betriebssystem, das Inhalte, Kontext und Prüfung in Einklang mit Continuous Delivery hält.",
  category: "Erklärung",
  section: "translation",
  order: 1
}
---

Ein Produkt kann kontinuierlich ausgeliefert werden, während seine Übersetzungen in einem separaten Release-Zyklus stecken bleiben. Quelleninhalte ändern sich im Git, jemand exportiert sie in ein Translationssystem, Bearbeiter arbeiten daran und jemand importiert das Ergebnis. Produkt und Sprachversionen geraten auseinander.

Glossia ist ein Sprach-OS, das auf einem anderen Grundprinzip basiert: Spracharbeit sollte demselben versionierten, überprüfbaren Lieferzyklus wie das Produkt selbst folgen.

## Das Problem ist größer als die Übersetzung.

Teams müssen Bedeutung bewahren, Terminologie anwenden, den Ton der Zielgruppe treffen und Inhalte in Übereinstimmung mit der Produktentwicklung aktualisieren. Diese Entscheidungen wirken sich auch auf Dokumentation, UI-Strings, Marketingseiten und agentengenerierte Texte gleichermaßen aus.

Ein Modell kann einen nützlichen Entwurf erstellen. Es weiß von selbst nicht, welche Sprachentscheidungen Ihre Organisation trifft, kann nicht erfassen, warum sich ein Ausdruck geändert hat, Dateiformate validieren oder die nächste Quellenrevision synchronisieren. Das Wiederholen eines Prompts ist kein Lieferungssystem.

Glossia verbindet Sprachkontext mit den Mechanismen der Generierung: Konfiguration, Änderunserkennung, Validierung, Fehlerwiederherstellung, Versionshistorie und Review.

## Inhalte bleiben beim Produkt.

Das Repository bleibt die maßgebliche Stelle für veröffentlichten Inhalt. Quelldateien, Konfiguration, generierte Übersetzungen und überprüfbare Änderungen können über Git und Pull-Requests weitergegeben werden. Teams brauchen keinen gehosteten Bearbeitungsschnittstelle als Autorität für jeden Satz, bevor sie eine lokalisierte Version veröffentlichen können.

So werden Sprachänderungen sichtbar neben dem Produktwechsel, der sie bewirkte. Ein Rezensent kann den Diff prüfen, CI kann das Ergebnis validieren und der gleiche Lieferweg kann es veröffentlichen.

Lesen Sie [Kontinuierliche Lokalisierung](./continuous-localization) für das Liefermodell und [Inhaltsbesitz](./content-ownership) für seine Tragbarkeit.

## Kontext ist eine Eingabe, kein Käfig.

Tonfall-Anleitungen und Terminologie helfen Menschen und Agenten, konsistent zu schreiben. Sie sind wiederverwendbare Sprachentscheidungen, nicht nur eine proprietäre Sammlung von Quell-Ziel-Segmentpaaren.

Übersetzungsspeicher bleiben nützlich für etablierte Übersetzungen und repetitiven Inhalt. Es geht nicht darum, sie zu verwerfen. Es geht darum, zu vermeiden, dass das Speicherformat eines Anbieters oder sein Bearbeitungsablauf der einzige Ort ist, wo das Sprachwissen eines Unternehmens leben kann.

## Verbesserung ist ein Kreislauf.

Glossias schrittweise-Verfeinerungs-Modell nutzt Inhalts-Hashes, um redundante Arbeit zu vermeiden, führt Validierung rund um Transformationen durch und zeigt Fehler an, damit ein Durchlauf wiederhergestellt werden kann. Menschliche Korrekturen können die nächste Iteration informieren, statt in eine isolierte Generierung zu verschwinden.

Lokalisierungsanalyse bietet eine weitere Eingabe: das Verständnis der Sprachen und Orte, die eine Zielgruppe nutzt, kann einem Team helfen, zu entscheiden, wo zu investieren. Es ist Grundlage für Priorisierung, nicht ein Versprechen, dass eine Übersetzung Wachstum bringt.

## Für wen passt das an?

Glossia ist besonders relevant, wenn Entwickler, Linguisten und Produktteams auf Repository-gemanagtem Inhalt zusammenarbeiten und diesen kontinuierlich veröffentlichen möchten. Es ist keine Forderung, dass jede Organisation ihr bestehendes TMS aufgeben sollte. Ein Team, dessen zentrale Anforderung ein ausgereifter browserbasierter Editor, Agentur-Koordination oder ein großer etablierter Speicher ist, mag einen anderen Workflow bevorzugen.

## Überprüfbare Implementierung

Glossias Code ist öffentlich verfügbar, einschließlich seiner Phoenix-Anwendung, der Rust CLI, des Web SDKs und der Bereitstellungsinfrastruktur. Das macht die Mechanismen der Spracharbeit überprüfbar statt als schwarze Kiste.

Glossia folgt einem Open-Core-Modell. Der Kern steht unter [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), die kommerzielle Nutzung, Änderungen, Weitergabe, Self-Hosting und konkurrierende gehostete Dienste gemäß ihren Bedingungen erlaubt. Der Code unter `ee/` ist einsehbar, aber nicht Open Source. Er unterliegt einer separaten [Enterprise-Lizenz](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md); der Produktionseinsatz erfordert eine schriftliche kommerzielle Vereinbarung.
