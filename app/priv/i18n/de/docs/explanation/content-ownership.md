%{
  title: "Inhaltseigentum und Portabilität",
  summary:
    "Warum repository-eigene Inhalte eine Rolle spielen und welche Abhängigkeiten die öffentliche Quelle entfernt und welche nicht.",
  category: "Erklärung",
  section: "translation",
  order: 3
}
---

Ein Unternehmen sollte in der Lage sein, seine Sprachwerkzeuge zu wechseln, ohne den von ihm bereits erstellten Inhalt oder die Möglichkeit zu verlieren, diesen Inhalt zu verifizieren.

## Besitz ist mehr als ein Export-Button

Das Exportieren von übersetzten Dateien ist nützlich, doch umfasst Portabilität auch die Korrekturhistorie, Sprachrichtlinien, Terminologie und Konfiguration, die für die Fortsetzung der Arbeit notwendig sind. Wenn diese nur in einem proprietären Arbeitsbereich angesiedelt sind, kann das Unternehmen seine Ergebnisse behalten, den Prozess jedoch verlieren, der diese ermöglicht hat.

Der Glossia-Repository-Workflow verwahrt veröffentlichte Quelldateien und übersetzte Dateien in Git. Pull-Request-Historie bleibt beim Repository, und die dateibasierte Konfiguration beschreibt die Transformation unabhängig von einer Bearbeitungssitzung im Browser.

## Sprachentscheidungen sollten wiederverwendbar sein

Stimme und Glossar-Richtlinien erfassen die organisatorische Intention. Glossia macht diesen Kontext Menschen und Integrationen verfügbar, einschließlich von Agenten über MCP. Das ist eine andere Art der Wiederverwendung als das Nachschlagen eines zuvor übersetzten Segments: Sie kann neuen Inhalt leiten, selbst wenn in einem Speicher kein passender Satz vorhanden ist.

Das macht segmentbasierte Übersetzungsspeicher nicht obsolet. Teams können wertvolle überprüfte Übersetzungen und spezialisierte Workflows besitzen, die sie beibehalten möchten. Glossia nimmt die Position ein, dass solche Ressourcen den Lieferprozess eines Unternehmens ergänzen sollen, anstatt eine zwingende proprietäre Autorität darüber zu werden.

## Öffentlicher Quellcode hilft, ist aber kein magischer Ausstieg.

Die Möglichkeit, die Implementierung zu prüfen und zu modifizieren, hilft Teams, zu verstehen, wie ihre Inhalte verarbeitet werden. Das bedeutet nicht, dass jede operative Abhängigkeit verschwindet. Eine bereitgestellte Glossia-Instanz benötigt weiterhin Datenbanken, Zugriff auf Modellanbieter für relevante Workflows, Zugangsdaten und Infrastruktur. Auch der dashboard-gesteuerte Sprachkontext benötigt einen expliziten Migrationsplan, falls ein Team Systemwechsel vornimmt.

Glossia folgt einem Open-Core-Modell. Der Kern steht unter [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), die kommerzielle Nutzung, Änderungen, Weitergabe, Self-Hosting und konkurrierende gehostete Dienste gemäß ihren Bedingungen erlaubt. Der Code unter `ee/` ist einsehbar, aber nicht Open Source. Er unterliegt einer separaten [Enterprise-Lizenz](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md); der Produktionseinsatz erfordert eine schriftliche kommerzielle Vereinbarung.

## Ein nützlicher Portabilitätstest

Prüfen Sie, ob das Team weiterhin seinen bestehenden übersetzten Inhalt prüfen, überarbeiten und veröffentlichen kann, wenn der Sprachdienst nicht verfügbar ist. Mit Repository-belegten Ausgaben erfordert die Veröffentlichung nicht, einen proprietären Editor neu zu öffnen, um nur die neueste Datei wiederherzustellen.

Fragen Sie sodann, wie Sprachrichtlinien, Zugangsdaten und Automatisierungen in ein anderes System wechseln. Das sind gesonderte Fragen, und sie explizit zu halten, ist nützlicher als ein unqualifiziertes Versprechen eines "kein Lock-in" ohne Einschränkung.
