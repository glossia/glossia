%{
  title: "Inhaltseigentum und Portabilität",
  summary:
    "Warum Inhalte, die dem Repository gehören, wichtig sind und welche Abhängigkeiten die öffentliche Quelle entfernt und nicht entfernt.",
  category: "Erklärung",
  section: "translation",
  order: 3
}
---

Ein Unternehmen sollte in der Lage sein, seine Sprachwerkzeuge zu ändern, ohne den Inhalt zu verlieren, den es bereits produziert hat, oder die Fähigkeit, diesen Inhalt zu verteilen.

## Eigentum ist mehr als ein Export-Button

Das Exportieren übersetzter Dateien ist nützlich, aber Portabilität umfasst auch den Prüfverlauf, die Sprachanweisungen, die Terminologie und die Konfiguration, die zum Weiterschreiten der Arbeit benötigt werden. Wenn diese nur in einem proprietären Arbeitsbereich untergebracht sind, kann das Unternehmen sein Ergebnis behalten, während es den Prozess verliert, der diesen hervorgebracht hat.

Der Repositories-Workflow von Glossia speichert veröffentlichte Quelldateien und übersetzte Dateien in Git. Der Pull-Request-Verlauf bleibt beim Repository, und die dateibasierte Konfiguration beschreibt die Transformation unabhängig von einer Browser-Bearbeitungssitzung.

## Sprachentscheidungen sollten wiederverwendbar sein

Stimme und Glossar-Anweisungen erfassen die Organisationsabsicht. Glossia macht diesen Kontext für Menschen und Integrationen verfügbar, einschließlich Agenten über MCP. Dies ist eine andere Art der Wiederverwendung als das Abrufen eines zuvor übersetzten Segments: Er kann neuen Inhalt leiten, selbst wenn kein passender Satz in einem Speicher liegt.

Das macht segmentbasierte Übersetzungsspeicher nicht überflüssig. Teams können wertvolle geprüfte Übersetzungen und spezialisierte Abläufe haben, die sie erhalten möchten. Die Haltung von Glossia ist, dass solche Ressourcen den Lieferprozess eines Unternehmens ergänzen sollten, statt eine verbindliche proprietäre Autorität darüber zu werden.

## Öffentlicher Quellcode hilft, ist aber kein magischer Ausstieg

Die Möglichkeit, die Implementierung zu inspizieren und zu ändern, hilft Teams zu verstehen, wie ihr Inhalt verarbeitet wird. Das bedeutet nicht, dass jede operative Abhängigkeit verschwindet. Eine bereitgestellte Glossia-Instanz benötigt weiterhin Datenbanken, Modell-Anbieter-Zugänge für relevante Prozesse, Anmeldeinformationen und Infrastruktur. Vom Dashboard verwalteter Sprachkontext braucht ebenfalls einen expliziten Migrationsplan, wenn ein Team Systeme wechselt.

Glossia folgt einem Open-Core-Modell. Der Kern steht unter Apache-2.0, die kommerzielle Nutzung, Änderungen, Weitergabe, Self-Hosting und konkurrierende gehostete Dienste gemäß ihren Bedingungen erlaubt. Der Code unter `ee/` ist einsehbar, aber nicht Open Source. Er unterliegt einer separaten Enterprise-Lizenz; der Produktionseinsatz erfordert eine schriftliche kommerzielle Vereinbarung. Siehe den [Lizenzhinweis](https://github.com/glossia/glossia/blob/main/LICENSE.md).

## Ein nützlicher Portabilitätstest

Prüfen Sie, ob das Team seinen bestehenden übersetzten Inhalt weiter untersuchen, prüfen und veröffentlichen kann, falls der Sprachdienst nicht verfügbar ist. Bei Repository-basierten Ausgaben erfordert die Veröffentlichung nicht das Wiederöffnen eines proprietären Editors, nur um die aktuellste Datei wiederherzustellen.

Dann fragen Sie, wie Sprachanweisungen, Authentifizierungsdaten und Automatisierungen in ein anderes System übertragen werden würden. Das sind separate Fragen, und es ist nützlicher, sie explizit zu halten, als "kein Lock-In" zu versprechen, ohne Einschränkung.
