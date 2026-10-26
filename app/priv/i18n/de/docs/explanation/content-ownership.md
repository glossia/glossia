%{
  title: "Inhaltseigentum und Portabilität",
  summary:
    "Warum Repository-eigener Inhalt wichtig ist und welche Abhängigkeiten die öffentliche Quelle entfernt oder nicht entfernt.",
  category: "Erklärung",
  section: "translation",
  order: 3
}
---

Ein Unternehmen sollte seine Sprachwerkzeuge wechseln können, ohne den bereits produzierten Inhalt oder die Fähigkeit, diesen Inhalt zu veröffentlichen, zu verlieren.

## Eigentum geht über einenExport-Button hinaus.

Das Exportieren übersetzter Dateien ist nützlich, aber Portabilität umfasst auch die Review-Historie, Sprachrichtlinien, Terminologie und die Konfiguration, die benötigt wird, um die Arbeit fortzusetzen. Wenn diese einzig in einem proprietären Arbeitsbereich existieren, kann das Unternehmen seinen Output behalten, während es den Prozess, der ihn erzeugt hat, verliert.

Der Repository-Workflow von Glossia bewahrt veröffentlichte Quelldateien und übersetzte Dateien in Git. Die Pull-Request-Historie bleibt beim Repository, und die an dateibasierten Konfiguration beschreibt die Transformation unabhängig von einer Browser-Bearbeitungssitzung.

## Sprachentscheidungen sollten wiederverwendbar sein.

Voice- und Glossarhinweise erfassen die organisatorische Absicht. Glossia macht diesen Kontext für Menschen und Integrationen verfügbar, einschließlich Agenten über MCP. Dies ist eine andere Art der Wiederverwendung als das Aufsuchen eines bereits übersetzten Segments: Es kann neuen Inhalt führen, selbst wenn es keinen passenden Satz in einem Speicher gibt.

Das macht segmentbasierte Übersetzungsspeicher nicht unbrauchbar. Teams können wertvoll überprüfte Übersetzungen und spezialisierte Arbeitsabläufe besitzen, die sie behalten möchten. Die Position von Glossia ist, dass solche Ressourcen den Lieferprozess eines Unternehmens ergänzen sollten, statt zu einer zwingenden proprietären Autorität darüber zu werden.

## Offener Quellcode hilft, ist aber kein magischer Ausweg.

Die Fähigkeit, die Implementierung zu prüfen und zu modifizieren, hilft Teams, zu verstehen, wie ihr Inhalt verarbeitet wird. Es bedeutet nicht, dass jede betriebliche Abhängigkeit verschwindet. Eine bereitgestellte Glossia-Instanz benötigt weiterhin Datenbanken, Zugang zu Model-Providern für relevante Workflows, Credentials und Infrastruktur. Kontext, der über ein Dashboard verwaltet wird, benötigt ebenfalls einen expliziten Migrationsplan, wenn ein Team Systeme ändert.

Die aktuelle O'Saasy-Lizenz begrenzt konkurrierende gehostete Dienste. Die Verfügbarkeit von offenem Quellcode ist nicht das Gleiche wie eine unbeschränkte Open-Source-Lizenz oder eine Garantie, dass ein Ersatzdienst unter jedem Geschäftsmodell betrieben werden kann. Siehe die [Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md) des Repositorys.

## Ein nützlicher Portabilitätstest

Fragen Sie, ob das Team seinen bestehenden übersetzten Inhalt prüfen, überarbeiten und veröffentlichen kann, wenn der Sprachdienst nicht verfügbar ist. Bei Repository-besitzten Outputs erfordert die Veröffentlichung nicht das Wiederaufschließen eines proprietären Editors, nur um die neueste Datei wiederherzustellen.

Dann fragen Sie, wie sich Sprachrichtlinien, Credentials und Automatisierung zu einem anderen System bewegen würden. Das sind separate Fragen, und es ist nützlicher, sie explizit zu halten, als unbegrenzt "kein Lock-in" zu versprechen.
