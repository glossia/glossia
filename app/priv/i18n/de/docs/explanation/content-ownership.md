%{
  title: "Inhaltseigentum und Portabilität",
  summary:
    "Warum Repository-eigener Inhalt wichtig ist und welche Abhängigkeiten die öffentliche Quelle entfernt und welche nicht entfernen.",
  category: "Erklärung",
  section: "translation",
  order: 3
}
---

Ein Unternehmen sollte sein Sprachwerkzeug ändern können, ohne den Inhalt, den es bereits produziert hat, zu verlieren, oder die Fähigkeit, diesen Inhalt zu veröffentlichen.

## Besitz ist mehr als ein Export-Button

Das Exportieren übersetzter Dateien ist nützlich, aber Portabilität umfasst auch die Überprüfungshistorie, Sprachrichtlinien, Terminologie und Konfiguration, die erforderlich sind, um die Arbeit fortzusetzen. Wenn diese nur innerhalb eines einzigen proprietären Workspace liegen, kann das Unternehmen seine Ausgabe behalten, während es den Prozess verliert, der sie erzeugt hat.

Der Repository-Arbeitsablauf von Glossia speichert veröffentlichte Source-Dateien und übersetzte Dateien in Git. Die Pull-Request-Historie bleibt beim Repository, und die dateibasierte Konfiguration beschreibt die Transformation unabhängig von einer Benutzersitzung zur Bearbeitung im Browser.

## Sprachentscheidungen sollten wiederverwendbar sein

Stimme und Glossar-Richtlinien fassen den organisatorischen Willen ein. Glossia macht diesen Kontext für Menschen und Integrationen verfügbar, einschließlich Agenten über MCP. Dies ist eine andere Art der Wiedervernutzung im Vergleich zur Suche nach einem zuvor übersetzten Segment: Es kann neuen Inhalt lenken, auch wenn sich kein passender Satz in einer Datenbank findet.

Das macht segmentbasierte Übersetzungsspeicher nicht veraltet. Teams können wertvolle überprüfte Übersetzungen und spezialisierte Arbeitsabläufe behalten wollen. Die Position von Glossia ist, dass solche Ressourcen einen Lieferprozess eines Unternehmens ergänzen sollten, anstatt eine zwingende proprietäre Autorität über ihn zu werden.

## Offene Quellen helfen, sind aber kein magischer Ausstiegspfad

Die Fähigkeit, die Implementierung zu prüfen und zu modifizieren, hilft Teams zu verstehen, wie ihr Inhalt verarbeitet wird. Das bedeutet nicht, dass jede operationale Abhängigkeit verschwindet. Eine bereitgestellte Glossia-Instanz benötigt trotzdem Datenbanken, Modellanbieter-Zugriff für relevante Arbeitsabläufe, Zugangsdaten und Infrastruktur. Auch der Dashboard verwaltete Sprachkontext benötigt einen expliziten Migrationsplan, wenn ein Team Systeme ändert.

Der Kern von Glossia ist Open Source unter Apache-2.0, was Selbsthosting und konkurrierende gehostete Dienste unter seiner Lizenzbedingungen erlaubt. Unternehmenscode unter `ee/` ist querverfügbar unter einer separaten Lizenz und erfordert eine schriftliche kommerzielle Vereinbarung für die Nutzung in der Produktion. Prüfen Sie den Repository's [Lizenzhinweis](https://github.com/glossia/glossia/blob/main/LICENSE.md) beim Planen einer Ersatzbereitstellung.

## Ein nützlicher Portabilitätstest

Fragen Sie, ob das Team weiterhin reproduzieren, überprüfen und veröffentlichen sein bestes übersetztes Inhalt, wenn die Sprachdienst uns verfüarbar. Mit Repository-eigenen Ausgaben, erfordert die Veröffentlichung nicht das Neuöffnen einer proprietären-Editor, die neuesten Datei zu wiederherstellen.

Fragen Sie, wie Spracheinrichtung, Zugangsdaten und Automatisierung verschoben würde zu einem anderen System. Diese sind getrennte Fragen, und halten sie explizit ist nützlicher als die ohne Qualifikation keine "Lock-in" zu versprechen.
